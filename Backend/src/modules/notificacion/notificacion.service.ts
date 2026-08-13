import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notificacion } from './notificacion.entity';
import { CrearNotificacionDto } from './dto/crear-notificacion.dto';
import { ActualizarNotificacionDto } from './dto/actualizar-notificacion.dto';
import { Usuario } from '../usuarios/usuario.entity';

@Injectable()
export class NotificacionService {
  constructor(
    @InjectRepository(Notificacion)
    private readonly notificacionRepository: Repository<Notificacion>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async crear(dto: CrearNotificacionDto): Promise<Notificacion> {
    const usuario = await this.usuarioRepository.findOneBy({ id: dto.idUsuario });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${dto.idUsuario} no encontrado`);
    }

    const { idUsuario, ...datos } = dto;
    const notificacion = this.notificacionRepository.create({ ...datos, usuario });
    return this.notificacionRepository.save(notificacion);
  }

  listarTodas(): Promise<Notificacion[]> {
    return this.notificacionRepository.find({
      relations: { usuario: true },
      order: { id: 'DESC' },
    });
  }

  async buscarPorId(id: number): Promise<Notificacion> {
    const notificacion = await this.notificacionRepository.findOne({
      where: { id },
      relations: { usuario: true },
    });
    if (!notificacion) {
      throw new NotFoundException(`Notificación con id ${id} no encontrada`);
    }
    return notificacion;
  }

  listarPorUsuario(idUsuario: number): Promise<Notificacion[]> {
    return this.notificacionRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true },
      order: { id: 'DESC' },
    });
  }

  async marcarLeida(id: number, leido = true): Promise<Notificacion> {
    const notificacion = await this.buscarPorId(id);
    notificacion.leido = leido;
    return this.notificacionRepository.save(notificacion);
  }

  async actualizar(id: number, dto: ActualizarNotificacionDto): Promise<Notificacion> {
    const notificacion = await this.buscarPorId(id);
    Object.assign(notificacion, dto);
    return this.notificacionRepository.save(notificacion);
  }

  async eliminar(id: number): Promise<void> {
    const notificacion = await this.buscarPorId(id);
    await this.notificacionRepository.delete(notificacion.id);
  }
}