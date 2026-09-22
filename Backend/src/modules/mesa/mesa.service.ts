import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
      restaurante,
    });
    return this.mesaRepository.save(mesa);
  }

  listarTodos(): Promise<Mesa[]> {
    return this.mesaRepository.find({ relations: { restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Mesa> {
    const mesa = await this.mesaRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!mesa) {
      throw new NotFoundException(`Mesa con id ${id} no encontrada`);
    }
    return mesa;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Mesa[]> {
    return this.mesaRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(id: number, dto: ActualizarMesaDto): Promise<Mesa> {
    const mesa = await this.buscarPorId(id);
    Object.assign(mesa, dto);
    return this.mesaRepository.save(mesa);
  }

  async eliminar(id: number): Promise<void> {
    const mesa = await this.buscarPorId(id);
    await this.mesaRepository.delete(mesa.id);
  }
}
