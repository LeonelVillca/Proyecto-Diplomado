import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThanOrEqual, Or, Repository } from 'typeorm';
import { Mesa } from './mesa.entity';
import { CrearMesaDto } from './dto/crear-mesa.dto';
import { ActualizarMesaDto } from './dto/actualizar-mesa.dto';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class MesaService {
  constructor(
    @InjectRepository(Mesa)
    private readonly mesaRepository: Repository<Mesa>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
  ) {}

  async crear(dto: CrearMesaDto): Promise<Mesa> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(
        `Restaurante con id ${dto.idRestaurante} no encontrado`,
      );
    }

    const mesa = this.mesaRepository.create({
      numeroMesa: dto.numeroMesa,
      capacidad: dto.capacidad,
      estado: dto.estado,
      estadoHasta:
        dto.estado === 'ocupada' || dto.estado === 'reservada'
          ? new Date(Date.now() + 60 * 60 * 1000)
          : null,
      restaurante,
    });
    return this.mesaRepository.save(mesa);
  }

  async listarTodos(): Promise<Mesa[]> {
    await this.liberarEstadosVencidos();
    return this.mesaRepository.find({ relations: { restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Mesa> {
    await this.liberarEstadosVencidos(id);
    const mesa = await this.mesaRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!mesa) {
      throw new NotFoundException(`Mesa con id ${id} no encontrada`);
    }
    return mesa;
  }

  async listarPorRestaurante(idRestaurante: number): Promise<Mesa[]> {
    await this.liberarEstadosVencidos();
    return this.mesaRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(id: number, dto: ActualizarMesaDto): Promise<Mesa> {
    return this.mesaRepository.manager.transaction(async (manager) => {
      await manager.query(
        'SELECT id_mesa FROM mesa WHERE id_mesa = $1 FOR UPDATE',
        [id],
      );
      const mesasRepo = manager.getRepository(Mesa);
      await this.liberarEstadosVencidos(id, mesasRepo);
      const mesa = await mesasRepo.findOne({
        where: { id },
        relations: { restaurante: true },
      });
      if (!mesa) {
        throw new NotFoundException(`Mesa con id ${id} no encontrada`);
      }

      Object.assign(mesa, dto);
      if (dto.estado !== undefined) {
        mesa.estadoHasta = ['ocupada', 'reservada'].includes(dto.estado)
          ? new Date(Date.now() + 60 * 60 * 1000)
          : null;
      }
      return mesasRepo.save(mesa);
    });
  }

  async eliminar(id: number): Promise<void> {
    const mesa = await this.buscarPorId(id);
    await this.mesaRepository.delete(mesa.id);
  }

  private async liberarEstadosVencidos(
    id?: number,
    repository: Repository<Mesa> = this.mesaRepository,
  ): Promise<void> {
    await repository.update(
      {
        ...(id === undefined ? {} : { id }),
        estado: In(['ocupada', 'reservada']),
        estadoHasta: Or(IsNull(), LessThanOrEqual(new Date())),
      },
      { estado: 'libre', estadoHasta: null },
    );
  }
}
