import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RolPermiso } from './rol-permiso.entity';
import { CrearRolPermisoDto } from './dto/crear-rol-permiso.dto';
import { Rol } from '../rol/rol.entity';
import { Permiso } from '../permiso/permiso.entity';

@Injectable()
export class RolPermisoService implements OnModuleInit {
  constructor(
    @InjectRepository(RolPermiso)
    private readonly rolPermisoRepository: Repository<RolPermiso>,
    @InjectRepository(Rol)
    private readonly rolRepository: Repository<Rol>,
    @InjectRepository(Permiso)
    private readonly permisoRepository: Repository<Permiso>,
  ) {}

  async onModuleInit() {
    // Definimos qué códigos van a cada rol
    const permisosAdminRestaurante = [
      'menu_dashboard', 'menu_perfil_restaurante', 'menu_mesas', 
      'menu_menus', 'menu_reservas', 'menu_resenas', 'menu_soporte'
    ];
    
    const permisosAdminSistema = [
      'menu_solicitudes', 'menu_usuarios', 'menu_roles', 
      'menu_asignar_roles', 'menu_permisos', 'menu_soporte', 'menu_moderacion'
    ];

    await this.asignarSiFaltan('admin_restaurante', permisosAdminRestaurante);
    await this.asignarSiFaltan('admin_sistema', permisosAdminSistema);
    console.log('Asignaciones de permisos predeterminadas sincronizadas.');
  }

  private async asignarSiFaltan(nombreRol: string, codigosPermiso: string[]) {
    const rol = await this.rolRepository.findOneBy({ nombre: nombreRol });
    if (!rol) return; // Si no existe el rol, no hacemos nada

    for (const codigo of codigosPermiso) {
      const permiso = await this.permisoRepository.findOneBy({ codigo });
      if (permiso) {
        const existe = await this.rolPermisoRepository.findOneBy({
          rol: { id: rol.id },
          permiso: { id: permiso.id },
        });
        if (!existe) {
          await this.rolPermisoRepository.save(
            this.rolPermisoRepository.create({ rol, permiso })
          );
        }
      }
    }
  }

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