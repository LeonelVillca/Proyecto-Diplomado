import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Solicitud } from './solicitud.entity';
import { CrearSolicitudDto } from './dto/crear-solicitud.dto';
import { ActualizarSolicitudDto } from './dto/actualizar-solicitud.dto';
import { Usuario } from '../usuarios/usuario.entity';

@Injectable()
export class SolicitudService {
  constructor(
    @InjectRepository(Solicitud)
    private readonly solicitudRepository: Repository<Solicitud>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async crear(dto: CrearSolicitudDto): Promise<Solicitud> {
    const usuario = await this.usuarioRepository.findOneBy({ id: dto.idUsuario });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${dto.idUsuario} no encontrado`);
    }

    const { idUsuario, ...datos } = dto;
    const solicitud = this.solicitudRepository.create({ ...datos, usuario });
    return this.solicitudRepository.save(solicitud);
  }

  listarTodos(): Promise<Solicitud[]> {
    return this.solicitudRepository.find({ relations: { usuario: true } });
  }

  async buscarPorId(id: number): Promise<Solicitud> {
    const solicitud = await this.solicitudRepository.findOne({
      where: { id },
      relations: { usuario: true },
    });
    if (!solicitud) {
      throw new NotFoundException(`Solicitud con id ${id} no encontrada`);
    }
    return solicitud;
  }

  listarPorUsuario(idUsuario: number): Promise<Solicitud[]> {
    return this.solicitudRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true },
    });
  }

  async actualizar(id: number, dto: ActualizarSolicitudDto): Promise<Solicitud> {
    const solicitud = await this.buscarPorId(id);
    Object.assign(solicitud, dto);
    return this.solicitudRepository.save(solicitud);
  }

  async eliminar(id: number): Promise<void> {
    const solicitud = await this.buscarPorId(id);
    await this.solicitudRepository.delete(solicitud.id);
  }
}