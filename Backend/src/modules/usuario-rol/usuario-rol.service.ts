import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UsuarioRol } from './usuario-rol.entity';
import { CrearUsuarioRolDto } from './dto/crear-usuario-rol.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Rol } from '../rol/rol.entity';

@Injectable()
export class UsuarioRolService {
  constructor(
    @InjectRepository(UsuarioRol)
    private readonly usuarioRolRepository: Repository<UsuarioRol>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(Rol)
    private readonly rolRepository: Repository<Rol>,
  ) {}

  async asignarRol(dto: CrearUsuarioRolDto): Promise<UsuarioRol> {
    const { idUsuario, idRol } = dto;

    const usuario = await this.usuarioRepository.findOneBy({ id: idUsuario });
    if (!usuario) {
      throw new NotFoundException(`Usuario con id ${idUsuario} no encontrado`);
    }

    const rol = await this.rolRepository.findOneBy({ id: idRol });
    if (!rol) {
      throw new NotFoundException(`Rol con id ${idRol} no encontrado`);
    }

    const existe = await this.usuarioRolRepository.findOneBy({
      usuario: { id: idUsuario },
      rol: { id: idRol },
    });
    if (existe) {
      return existe;
    }

    const asignacion = this.usuarioRolRepository.create({ usuario, rol });
    return this.usuarioRolRepository.save(asignacion);
  }

  listarTodos(): Promise<UsuarioRol[]> {
    return this.usuarioRolRepository.find({
      relations: { usuario: true, rol: true },
    });
  }

  listarRolesPorUsuario(idUsuario: number): Promise<UsuarioRol[]> {
    return this.usuarioRolRepository.find({
      relations: { rol: true },
      where: { usuario: { id: idUsuario } },
    });
  }

  listarUsuariosPorRol(idRol: number): Promise<UsuarioRol[]> {
    return this.usuarioRolRepository.find({
      relations: { usuario: true },
      where: { rol: { id: idRol } },
    });
  }

  async eliminarAsignacion(idUsuario: number, idRol: number): Promise<void> {
    const asignacion = await this.usuarioRolRepository.findOneBy({
      usuario: { id: idUsuario },
      rol: { id: idRol },
    });
    if (!asignacion) {
      throw new NotFoundException(
        `Asignación usuario ${idUsuario} / rol ${idRol} no encontrada`,
      );
    }
    await this.usuarioRolRepository.delete({
      usuario: { id: idUsuario },
      rol: { id: idRol },
    });
  }
}
