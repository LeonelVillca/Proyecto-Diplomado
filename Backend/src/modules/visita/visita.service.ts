import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Visita } from './visita.entity';
import { CrearVisitaDto } from './dto/crear-visita.dto';
import { ActualizarVisitaDto } from './dto/actualizar-visita.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Usuario } from '../usuarios/usuario.entity';

@Injectable()
export class VisitaService {
  constructor(
    @InjectRepository(Visita)
    private readonly visitaRepository: Repository<Visita>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async crear(dto: CrearVisitaDto): Promise<Visita> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${dto.idRestaurante} no encontrado`);
    }

    if (dto.idUsuario !== undefined) {
      const usuario = await this.usuarioRepository.findOneBy({ id: dto.idUsuario });
      if (!usuario) {
        throw new NotFoundException(`Usuario con id ${dto.idUsuario} no encontrado`);
      }
    }

    const { idRestaurante, idUsuario, ...datos } = dto;
    const visita = this.visitaRepository.create({
      ...datos,
      restaurante,
      usuario: idUsuario ? { id: idUsuario } : null,
    });
    return this.visitaRepository.save(visita);
  }

  listarTodas(): Promise<Visita[]> {
    return this.visitaRepository.find({
      relations: { restaurante: true, usuario: true },
      order: { id: 'DESC' },
    });
  }

  async buscarPorId(id: number): Promise<Visita> {
    const visita = await this.visitaRepository.findOne({
      where: { id },
      relations: { restaurante: true, usuario: true },
    });
    if (!visita) {
      throw new NotFoundException(`Visita con id ${id} no encontrada`);
    }
    return visita;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Visita[]> {
    return this.visitaRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true, usuario: true },
      order: { id: 'DESC' },
    });
  }

  async actualizar(id: number, dto: ActualizarVisitaDto): Promise<Visita> {
    const visita = await this.buscarPorId(id);
    Object.assign(visita, dto);
    return this.visitaRepository.save(visita);
  }

  async eliminar(id: number): Promise<void> {
    const visita = await this.buscarPorId(id);
    await this.visitaRepository.delete(visita.id);
  }
}