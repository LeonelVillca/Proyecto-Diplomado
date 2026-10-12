import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Mesa } from './mesa.entity';
import { CrearMesaDto } from './dto/crear-mesa.dto';
import { ActualizarMesaDto } from './dto/actualizar-mesa.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { ActualizarEstadoHorarioDto } from './dto/actualizar-estado-horario.dto';
import {
  actualizarBloqueoHorario,
  DURACION_ESTADO_MESA_MINUTOS,
  liberarEstadosMesaVencidos,
} from './mesa-estado';

@Injectable()
export class MesaService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    @InjectRepository(Mesa)
    private readonly mesaRepository: Repository<Mesa>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
  ) {}

  // Crea una mesa.
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
          ? new Date(Date.now() + DURACION_ESTADO_MESA_MINUTOS * 60000)
          : null,
      restaurante,
    });
    return this.mesaRepository.save(mesa);
  }

  // Lista las mesas.
  async listarTodos(): Promise<Mesa[]> {
    await liberarEstadosMesaVencidos(this.mesaRepository);
    return this.mesaRepository.find({ relations: { restaurante: true } });
  }

  // Busca una mesa por su identificador.
  async buscarPorId(id: number): Promise<Mesa> {
    await liberarEstadosMesaVencidos(this.mesaRepository, id);
    const mesa = await this.mesaRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!mesa) {
      throw new NotFoundException(`Mesa con id ${id} no encontrada`);
    }
    return mesa;
  }

  // Lista las mesas de un restaurante.
  async listarPorRestaurante(idRestaurante: number): Promise<Mesa[]> {
    await liberarEstadosMesaVencidos(this.mesaRepository);
    return this.mesaRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  // Actualiza una mesa.
  async actualizar(id: number, dto: ActualizarMesaDto): Promise<Mesa> {
    return this.mesaRepository.manager.transaction(async (manager) => {
      await manager.query(
        'SELECT id_mesa FROM mesa WHERE id_mesa = $1 FOR UPDATE',
        [id],
      );
      const mesasRepo = manager.getRepository(Mesa);
      await liberarEstadosMesaVencidos(mesasRepo, id);
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
          ? new Date(Date.now() + DURACION_ESTADO_MESA_MINUTOS * 60000)
          : null;
      }
      return mesasRepo.save(mesa);
    });
  }

  // Actualiza el estado de una mesa para un horario.
  async actualizarEstadoHorario(id: number, dto: ActualizarEstadoHorarioDto) {
    return this.mesaRepository.manager.transaction(async (manager) => {
      return actualizarBloqueoHorario(id, dto, (sql, params) =>
        manager.query(sql, params),
      );
    });
  }

  // Elimina una mesa.
  async eliminar(id: number): Promise<void> {
    const mesa = await this.buscarPorId(id);
    await this.mesaRepository.delete(mesa.id);
  }
}
