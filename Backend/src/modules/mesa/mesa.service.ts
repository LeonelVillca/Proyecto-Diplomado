import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThanOrEqual, Or, Repository } from 'typeorm';
import { Mesa } from './mesa.entity';
import { CrearMesaDto } from './dto/crear-mesa.dto';
import { ActualizarMesaDto } from './dto/actualizar-mesa.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { ActualizarEstadoHorarioDto } from './dto/actualizar-estado-horario.dto';

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

  async actualizarEstadoHorario(id: number, dto: ActualizarEstadoHorarioDto) {
    return this.mesaRepository.manager.transaction(async (manager) => {
      const rows: Array<{ id_mesa: number; estado: string }> = await manager.query(
        'SELECT id_mesa, estado FROM mesa WHERE id_mesa = $1 FOR UPDATE',
        [id],
      );
      if (!rows.length) throw new NotFoundException('Mesa no encontrada');
      if (rows[0].estado === 'inactiva') {
        throw new BadRequestException('La mesa está fuera de servicio');
      }

      const inicio = 'CAST($2 AS date) + CAST($3 AS time)';
      if (dto.estado === 'libre') {
        await manager.query(
          'DELETE FROM mesa_bloqueo_horario WHERE id_mesa = $1 AND fecha = $2 AND hora = $3',
          [id, dto.fecha, dto.hora],
        );
      } else {
        const reservas: unknown[] = await manager.query(
          `SELECT 1 FROM reservas WHERE id_mesa = $1
           AND estado IN ('pendiente', 'confirmada')
           AND fecha + hora - INTERVAL '30 minutes' < ${inicio} + INTERVAL '60 minutes'
           AND fecha + hora + (duracion_minutos * INTERVAL '1 minute') > ${inicio}
           LIMIT 1`,
          [id, dto.fecha, dto.hora],
        );
        if (reservas.length) {
          throw new BadRequestException('Ya existe una reserva en ese horario');
        }
        const otrosBloqueos: unknown[] = await manager.query(
          `SELECT 1 FROM mesa_bloqueo_horario WHERE id_mesa = $1
           AND fecha + hora < ${inicio} + INTERVAL '60 minutes'
           AND fecha + hora + INTERVAL '60 minutes' > ${inicio}
           AND NOT (fecha = $2 AND hora = $3) LIMIT 1`,
          [id, dto.fecha, dto.hora],
        );
        if (otrosBloqueos.length) {
          throw new BadRequestException(
            'Ese horario se cruza con otro bloqueo manual de la mesa',
          );
        }
        await manager.query(
          `INSERT INTO mesa_bloqueo_horario (id_mesa, fecha, hora, estado)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (id_mesa, fecha, hora) DO UPDATE SET estado = EXCLUDED.estado`,
          [id, dto.fecha, dto.hora, dto.estado],
        );
      }
      return { idMesa: id, ...dto };
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
