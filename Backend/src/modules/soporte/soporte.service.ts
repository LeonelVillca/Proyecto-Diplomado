import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Soporte, ESTADO_SOPORTE } from './soporte.entity';
import { CrearSoporteDto } from './dto/crear-soporte.dto';
import { ActualizarSoporteDto } from './dto/actualizar-soporte.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { CategoriaSoporte } from '../categoria-soporte/categoria-soporte.entity';

@Injectable()
export class SoporteService {
  constructor(
    @InjectRepository(Soporte)
    private readonly soporteRepository: Repository<Soporte>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(CategoriaSoporte)
    private readonly categoriaRepository: Repository<CategoriaSoporte>,
  ) {}

  async crear(dto: CrearSoporteDto): Promise<Soporte> {
    const usuario = await this.usuarioRepository.findOneBy({ id: dto.idUsuario });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${dto.idUsuario} no encontrado`);
    }

    const categoria = await this.categoriaRepository.findOneBy({
      id: dto.idCategoriaSoporte,
    });
    if (!categoria) {
      throw new NotFoundException(
        `Categoría de soporte con id ${dto.idCategoriaSoporte} no encontrada`,
      );
    }

    const { idUsuario, idCategoriaSoporte, ...datos } = dto;
    const soporte = this.soporteRepository.create({
      ...datos,
      usuario,
      categoriaSoporte: categoria,
    });
    return this.soporteRepository.save(soporte);
  }

  listarTodos(): Promise<Soporte[]> {
    return this.soporteRepository.find({
      relations: { usuario: true, categoriaSoporte: true },
      order: { id: 'DESC' },
    });
  }

  async buscarPorId(id: number): Promise<Soporte> {
    const soporte = await this.soporteRepository.findOne({
      where: { id },
      relations: { usuario: true, categoriaSoporte: true },
    });
    if (!soporte) {
      throw new NotFoundException(`Soporte con id ${id} no encontrado`);
    }
    return soporte;
  }

  listarPorUsuario(idUsuario: number): Promise<Soporte[]> {
    return this.soporteRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true, categoriaSoporte: true },
      order: { id: 'DESC' },
    });
  }

  listarPorCategoria(idCategoria: number): Promise<Soporte[]> {
    return this.soporteRepository.find({
      where: { categoriaSoporte: { id: idCategoria } },
      relations: { usuario: true, categoriaSoporte: true },
      order: { id: 'DESC' },
    });
  }

  async actualizar(id: number, dto: ActualizarSoporteDto): Promise<Soporte> {
    const soporte = await this.buscarPorId(id);

    // Responder un ticket: se marca respondida y se sella la fecha de respuesta.
    if (dto.respuesta !== undefined && dto.estado === undefined) {
      (soporte as { estado: (typeof ESTADO_SOPORTE)[number] }).estado =
        'respondida';
      soporte.fechaRespuesta = new Date();
    }
    if (dto.estado === 'respondida' && soporte.fechaRespuesta === null) {
      soporte.fechaRespuesta = new Date();
    }

    Object.assign(soporte, dto);
    return this.soporteRepository.save(soporte);
  }

  async eliminar(id: number): Promise<void> {
    const soporte = await this.buscarPorId(id);
    await this.soporteRepository.delete(soporte.id);
  }
}