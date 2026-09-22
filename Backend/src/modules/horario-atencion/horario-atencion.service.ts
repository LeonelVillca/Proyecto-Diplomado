import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HorarioAtencion } from './horario-atencion.entity';
import { CrearHorarioAtencionDto } from './dto/crear-horario-atencion.dto';
import { ActualizarHorarioAtencionDto } from './dto/actualizar-horario-atencion.dto';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class HorarioAtencionService {
  constructor(
    @InjectRepository(HorarioAtencion)
    private readonly horarioRepository: Repository<HorarioAtencion>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
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
}
