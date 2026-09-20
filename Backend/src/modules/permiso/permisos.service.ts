import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Permiso } from './permiso.entity';
import { CrearPermisoDto } from './dto/crear-permiso.dto';
import { ActualizarPermisoDto } from './dto/actualizar-permiso.dto';

@Injectable()
export class PermisosService implements OnModuleInit {
  constructor(
    @InjectRepository(Permiso)
    private readonly permisoRepository: Repository<Permiso>,
  ) {}

  async onModuleInit() {
    const defaultPermisos = [
      { nombre: 'Menú Solicitudes', codigo: 'menu_solicitudes', descripcion: 'Aprobar o rechazar solicitudes' },
      { nombre: 'Menú Usuarios', codigo: 'menu_usuarios', descripcion: 'Gestión de usuarios' },
      { nombre: 'Menú Restaurantes', codigo: 'menu_restaurantes', descripcion: 'Gestión de cuentas de restaurantes' },
      { nombre: 'Menú Roles', codigo: 'menu_roles', descripcion: 'Gestión y listado de roles' },
      { nombre: 'Menú Asignar Roles', codigo: 'menu_asignar_roles', descripcion: 'Asignar roles a usuarios' },
      { nombre: 'Menú Permisos', codigo: 'menu_permisos', descripcion: 'Configuración de permisos por rol' },
      { nombre: 'Menú Soporte', codigo: 'menu_soporte', descripcion: 'Centro de ayuda y tickets' },
      { nombre: 'Menú Moderación', codigo: 'menu_moderacion', descripcion: 'Ver y moderar contenido' },
      
      { nombre: 'Menú Dashboard', codigo: 'menu_dashboard', descripcion: 'Acceso al Dashboard general' },
      { nombre: 'Menú Perfil Restaurante', codigo: 'menu_perfil_restaurante', descripcion: 'Configurar datos del restaurante' },
      { nombre: 'Menú Mesas y Horarios', codigo: 'menu_mesas', descripcion: 'Gestión de mesas y horarios' },
      { nombre: 'Menú Gestión de Menús', codigo: 'menu_menus', descripcion: 'Gestión de platillos y menú' },
      { nombre: 'Menú Reservas', codigo: 'menu_reservas', descripcion: 'Gestión de reservas entrantes' },
      { nombre: 'Menú Reseñas', codigo: 'menu_resenas', descripcion: 'Ver y responder reseñas' },
    ];

    for (const p of defaultPermisos) {
      let permiso = await this.permisoRepository.findOneBy({ codigo: p.codigo });
      if (!permiso) {
        permiso = this.permisoRepository.create(p);
        await this.permisoRepository.save(permiso);
      }
    }
    console.log('Permisos sincronizados correctamente.');
  }

  crear(dto: CrearPermisoDto): Promise<Permiso> {
    const permiso = this.permisoRepository.create(dto);
    return this.permisoRepository.save(permiso);
  }

  listarTodos(): Promise<Permiso[]> {
    return this.permisoRepository.find();
  }

  async buscarPorId(id: number): Promise<Permiso> {
    const permiso = await this.permisoRepository.findOneBy({ id });
    if (!permiso) {
      throw new NotFoundException(`Permiso con id ${id} no encontrado`);
    }
    return permiso;
  }

  async buscarPorCodigo(codigo: string): Promise<Permiso | null> {
    return this.permisoRepository.findOneBy({ codigo });
  }

  async actualizar(id: number, dto: ActualizarPermisoDto): Promise<Permiso> {
    const permiso = await this.buscarPorId(id);
    Object.assign(permiso, dto);
    return this.permisoRepository.save(permiso);
  }

  async eliminar(id: number): Promise<void> {
    const permiso = await this.buscarPorId(id);
    await this.permisoRepository.delete(permiso.id);
  }
}
