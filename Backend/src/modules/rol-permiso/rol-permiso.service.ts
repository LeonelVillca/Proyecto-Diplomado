import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RolPermiso } from './rol-permiso.entity';
import { CrearRolPermisoDto } from './dto/crear-rol-permiso.dto';
import { Rol } from '../rol/rol.entity';
import { Permiso } from '../permiso/permiso.entity';

@Injectable()
export class RolPermisoService {
  constructor(
    @InjectRepository(RolPermiso)
    private readonly rolPermisoRepository: Repository<RolPermiso>,
    @InjectRepository(Rol)
    private readonly rolRepository: Repository<Rol>,
    @InjectRepository(Permiso)
    private readonly permisoRepository: Repository<Permiso>,
  ) {}

  async asignarPermiso(dto: CrearRolPermisoDto): Promise<RolPermiso> {
    const { idRol, idPermiso } = dto;

    const rol = await this.rolRepository.findOneBy({ id: idRol });
    if (!rol) {
      throw new NotFoundException(`Rol con id ${idRol} no encontrado`);
    }

    const permiso = await this.permisoRepository.findOneBy({ id: idPermiso });
    if (!permiso) {
      throw new NotFoundException(`Permiso con id ${idPermiso} no encontrado`);
    }

    const existe = await this.rolPermisoRepository.findOneBy({
      rol: { id: idRol },
      permiso: { id: idPermiso },
    });
    if (existe) {
      return existe;
    }

    const asignacion = this.rolPermisoRepository.create({ rol, permiso });
    return this.rolPermisoRepository.save(asignacion);
  }

  listarTodos(): Promise<RolPermiso[]> {
    return this.rolPermisoRepository.find({
      relations: { rol: true, permiso: true },
    });
  }

  listarPermisosPorRol(idRol: number): Promise<RolPermiso[]> {
    return this.rolPermisoRepository.find({
      relations: { permiso: true },
      where: { rol: { id: idRol } },
    });
  }

  listarRolesPorPermiso(idPermiso: number): Promise<RolPermiso[]> {
    return this.rolPermisoRepository.find({
      relations: { rol: true },
      where: { permiso: { id: idPermiso } },
    });
  }

  async eliminarAsignacion(idRol: number, idPermiso: number): Promise<void> {
    const asignacion = await this.rolPermisoRepository.findOneBy({
      rol: { id: idRol },
      permiso: { id: idPermiso },
    });
    if (!asignacion) {
      throw new NotFoundException(
        `Asignación rol ${idRol} / permiso ${idPermiso} no encontrada`,
      );
    }
    await this.rolPermisoRepository.delete({
      rol: { id: idRol },
      permiso: { id: idPermiso },
    });
  }
}