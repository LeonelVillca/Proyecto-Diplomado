import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ubicacion } from './ubicacion.entity';
import { CrearUbicacionDto } from './dto/crear-ubicacion.dto';
import { ActualizarUbicacionDto } from './dto/actualizar-ubicacion.dto';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class UbicacionService {
  constructor(
    @InjectRepository(Ubicacion)
    private readonly ubicacionRepository: Repository<Ubicacion>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
  ) {}

  async crear(dto: CrearUbicacionDto): Promise<Ubicacion> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${dto.idRestaurante} no encontrado`);
    }

    const { idRestaurante, ...datos } = dto;
    const ubicacion = this.ubicacionRepository.create({ ...datos, restaurante });
    return this.ubicacionRepository.save(ubicacion);
  }

  listarTodos(): Promise<Ubicacion[]> {
    return this.ubicacionRepository.find({ relations: { restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Ubicacion> {
    const ubicacion = await this.ubicacionRepository.findOne({
      where: { id },
      relations: { restaurante: true },
    });
    if (!ubicacion) {
      throw new NotFoundException(`Ubicación con id ${id} no encontrada`);
    }
    return ubicacion;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Ubicacion[]> {
    return this.ubicacionRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(id: number, dto: ActualizarUbicacionDto): Promise<Ubicacion> {
    const ubicacion = await this.buscarPorId(id);
    Object.assign(ubicacion, dto);
    return this.ubicacionRepository.save(ubicacion);
  }

  async eliminar(id: number): Promise<void> {
    const ubicacion = await this.buscarPorId(id);
    await this.ubicacionRepository.delete(ubicacion.id);
  }
}