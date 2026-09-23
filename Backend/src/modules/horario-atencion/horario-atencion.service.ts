import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HorarioAtencion } from './horario-atencion.entity';
import { CrearHorarioAtencionDto } from './dto/crear-horario-atencion.dto';
import { ActualizarHorarioAtencionDto } from './dto/actualizar-horario-atencion.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { ExcepcionHorario } from './excepcion-horario.entity';
import { CrearExcepcionHorarioDto } from './dto/crear-excepcion-horario.dto';
import { ActualizarExcepcionHorarioDto } from './dto/actualizar-excepcion-horario.dto';

@Injectable()
export class HorarioAtencionService {
  constructor(
    @InjectRepository(HorarioAtencion)
    private readonly horarioRepository: Repository<HorarioAtencion>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(ExcepcionHorario)
    private readonly excepcionRepository: Repository<ExcepcionHorario>,
  ) {}

  async crear(dto: CrearHorarioAtencionDto): Promise<HorarioAtencion> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(
        `Restaurante con id ${dto.idRestaurante} no encontrado`,
      );
    }

    const horario = this.horarioRepository.create({
      diaSemana: dto.diaSemana,
      horaInicio: dto.horaInicio,
      horaFin: dto.horaFin,
      restaurante,
    });
    return this.horarioRepository.save(horario);
  }

  listarTodos(): Promise<HorarioAtencion[]> {
    return this.horarioRepository.find({ relations: { restaurante: true } });
  }

  async buscarPorId(id: number): Promise<HorarioAtencion> {
    const horario = await this.horarioRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!horario) {
      throw new NotFoundException(`Horario con id ${id} no encontrado`);
    }
    return horario;
  }

  listarPorRestaurante(idRestaurante: number): Promise<HorarioAtencion[]> {
    return this.horarioRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(
    id: number,
    dto: ActualizarHorarioAtencionDto,
  ): Promise<HorarioAtencion> {
    const horario = await this.buscarPorId(id);
    Object.assign(horario, dto);
    return this.horarioRepository.save(horario);
  }

  async eliminar(id: number): Promise<void> {
    const horario = await this.buscarPorId(id);
    await this.horarioRepository.delete(horario.id);
  }

  async crearExcepcion(
    dto: CrearExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(
        `Restaurante con id ${dto.idRestaurante} no encontrado`,
      );
    }
    this.validarExcepcion(dto.cerrado, dto.horaInicio, dto.horaFin);
    return this.excepcionRepository.save(
      this.excepcionRepository.create({
        restaurante,
        fecha: dto.fecha,
        cerrado: dto.cerrado,
        horaInicio: dto.horaInicio ?? null,
        horaFin: dto.horaFin ?? null,
        motivo: dto.motivo ?? null,
      }),
    );
  }

  listarExcepciones(idRestaurante: number): Promise<ExcepcionHorario[]> {
    return this.excepcionRepository.find({
      where: { restaurante: { id: idRestaurante } },
      order: { fecha: 'ASC' },
    });
  }

  async actualizarExcepcion(
    id: number,
    dto: ActualizarExcepcionHorarioDto,
  ): Promise<ExcepcionHorario> {
    const excepcion = await this.buscarExcepcion(id);
    Object.assign(excepcion, dto);
    this.validarExcepcion(
      excepcion.cerrado,
      excepcion.horaInicio ?? undefined,
      excepcion.horaFin ?? undefined,
    );
    if (excepcion.cerrado) {
      excepcion.horaInicio = null;
      excepcion.horaFin = null;
    }
    return this.excepcionRepository.save(excepcion);
  }

  async eliminarExcepcion(id: number): Promise<void> {
    const excepcion = await this.buscarExcepcion(id);
    await this.excepcionRepository.remove(excepcion);
  }

  private async buscarExcepcion(id: number): Promise<ExcepcionHorario> {
    const excepcion = await this.excepcionRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!excepcion) {
      throw new NotFoundException(`Excepción de horario #${id} no encontrada`);
    }
    return excepcion;
  }

  private validarExcepcion(
    cerrado: boolean,
    horaInicio?: string,
    horaFin?: string,
  ): void {
    if (!cerrado && (!horaInicio || !horaFin || horaInicio >= horaFin)) {
      throw new BadRequestException(
        'Un horario especial debe tener una franja válida.',
      );
    }
  }
}
