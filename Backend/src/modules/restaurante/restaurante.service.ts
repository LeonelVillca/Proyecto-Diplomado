import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Restaurante } from './restaurante.entity';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { Solicitud } from '../solicitud/solicitud.entity';

@Injectable()
export class RestauranteService {
  constructor(
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Solicitud)
    private readonly solicitudRepository: Repository<Solicitud>,
  ) {}

  async crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    if (dto.idSolicitud !== undefined) {
      const solicitud = await this.solicitudRepository.findOneBy({
        id: dto.idSolicitud,
      });
      if (!solicitud) {
        throw new NotFoundException(`Solicitud con id ${dto.idSolicitud} no encontrada`);
      }
    }

    const { idSolicitud, ...datos } = dto;
    const restaurante = this.restauranteRepository.create({
      ...datos,
      solicitud: idSolicitud ? { id: idSolicitud } : null,
    });
    return this.restauranteRepository.save(restaurante);
  }

  listarTodos(): Promise<Restaurante[]> {
    return this.restauranteRepository.find({ relations: { solicitud: true } });
  }

  async buscarPorId(id: number): Promise<Restaurante> {
    const restaurante = await this.restauranteRepository.findOne({
      where: { id },
      relations: { solicitud: true },
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${id} no encontrado`);
    }
    return restaurante;
  }

  async actualizar(id: number, dto: ActualizarRestauranteDto): Promise<Restaurante> {
    const restaurante = await this.buscarPorId(id);

    if (dto.idSolicitud !== undefined) {
      const solicitud = await this.solicitudRepository.findOneBy({
        id: dto.idSolicitud,
      });
      if (!solicitud) {
        throw new NotFoundException(`Solicitud con id ${dto.idSolicitud} no encontrada`);
      }
      restaurante.solicitud = solicitud;
    }

    const { idSolicitud: _ignorado, ...datos } = dto;
    Object.assign(restaurante, datos);
    return this.restauranteRepository.save(restaurante);
  }

  async eliminar(id: number): Promise<void> {
    const restaurante = await this.buscarPorId(id);
    await this.restauranteRepository.delete(restaurante.id);
  }
}