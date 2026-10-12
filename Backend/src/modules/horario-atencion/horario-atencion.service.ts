import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { HorarioAtencion } from './horario-atencion.entity';
import { CrearHorarioAtencionDto } from './dto/crear-horario-atencion.dto';
import { DatosHorarioAtencionDto } from './dto/datos-horario-atencion.dto';
import { ActualizarHorarioAtencionDto } from './dto/actualizar-horario-atencion.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { ExcepcionHorario } from './excepcion-horario.entity';
import { CrearExcepcionHorarioDto } from './dto/crear-excepcion-horario.dto';
import { ActualizarExcepcionHorarioDto } from './dto/actualizar-excepcion-horario.dto';

@Injectable()
export class HorarioAtencionService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    @InjectRepository(HorarioAtencion)
    private readonly horarioRepository: Repository<HorarioAtencion>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(ExcepcionHorario)
    private readonly excepcionRepository: Repository<ExcepcionHorario>,
  ) {}

  // Crea un horario de atención.
  async crear(dto: CrearHorarioAtencionDto): Promise<HorarioAtencion> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(
        `Restaurante con id ${dto.idRestaurante} no encontrado`,
      );
    }
    const [horario] = await this.crearEnRestaurante(
      this.horarioRepository.manager,
      restaurante,
      [dto],
    );
    return horario;
  }

  // Crea un horario para un restaurante.
  crearEnRestaurante(
    manager: EntityManager,
    restaurante: Restaurante,
    datos: DatosHorarioAtencionDto[],
  ): Promise<HorarioAtencion[]> {
    if (!datos.length) return Promise.resolve([]);
    const repository = manager.getRepository(HorarioAtencion);
    return repository.save(
      datos.map((horario) =>
        repository.create({
          restaurante,
          diaSemana: horario.diaSemana,
          horaInicio: horario.horaInicio,
          horaFin: horario.horaFin,
        }),
      ),
    );
  }

  // Reemplaza los horarios semanales de un restaurante.
  async reemplazarSemanales(
    manager: EntityManager,
    idRestaurante: number,
    datos: DatosHorarioAtencionDto[],
  ): Promise<void> {
    await manager.getRepository(HorarioAtencion).delete({
      restaurante: { id: idRestaurante },
    });
    await this.crearEnRestaurante(
      manager,
      { id: idRestaurante } as Restaurante,
      datos,
    );
  }

  // Lista los horarios de atención.
  listarTodos(): Promise<HorarioAtencion[]> {
    return this.horarioRepository.find({ relations: { restaurante: true } });
  }

  // Busca un horario de atención por su identificador.
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

  // Lista los horarios de atención de un restaurante.
  listarPorRestaurante(idRestaurante: number): Promise<HorarioAtencion[]> {
    return this.horarioRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  // Actualiza un horario de atención.
  async actualizar(
    id: number,
    dto: ActualizarHorarioAtencionDto,
  ): Promise<HorarioAtencion> {
    const horario = await this.buscarPorId(id);
    Object.assign(horario, dto);
    return this.horarioRepository.save(horario);
  }

  // Elimina un horario de atención.
  async eliminar(id: number): Promise<void> {
    const horario = await this.buscarPorId(id);
    await this.horarioRepository.delete(horario.id);
  }

  // Crea una excepción de horario.
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

  // Lista las excepciones de horario de un restaurante.
  listarExcepciones(idRestaurante: number): Promise<ExcepcionHorario[]> {
    return this.excepcionRepository.find({
      where: { restaurante: { id: idRestaurante } },
      order: { fecha: 'ASC' },
    });
  }

  // Actualiza una excepción de horario.
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

  // Elimina una excepción de horario.
  async eliminarExcepcion(id: number): Promise<void> {
    const excepcion = await this.buscarExcepcion(id);
    await this.excepcionRepository.remove(excepcion);
  }

  // Busca una excepción de horario.
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

  // Valida los datos de una excepción de horario.
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
