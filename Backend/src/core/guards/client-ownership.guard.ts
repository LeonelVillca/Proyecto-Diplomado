import { Injectable, CanActivate, ExecutionContext, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { SetMetadata } from '@nestjs/common';
import { Soporte } from '../../modules/soporte/soporte.entity';
import { Notificacion } from '../../modules/notificacion/notificacion.entity';
import { Resena } from '../../modules/resenas/resena.entity';
import { UsuarioRol } from '../../modules/usuario-rol/usuario-rol.entity';

export const CLIENT_RESOURCE_KEY = 'client_resource';
export const CheckClientOwnership = (resource: 'soporte' | 'notificacion' | 'resena') => 
  SetMetadata(CLIENT_RESOURCE_KEY, resource);

@Injectable()
export class ClientOwnershipGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private dataSource: DataSource,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const resourceType = this.reflector.get<string>(CLIENT_RESOURCE_KEY, context.getHandler());
    
    if (!resourceType) {
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const { user, params, body } = req;

    if (!user) {
      return false;
    }

    // 1. Verificamos si es admin_sistema (para dejarlo pasar libremente)
    const usuarioRoles = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: user.id },
      relations: { rol: true },
    });
    const isAdminSistema = usuarioRoles.some((ur) => ur.rol.nombre === 'admin_sistema');
    
    if (isAdminSistema) {
      return true;
    }

    // 2. Control estricto para clientes regulares
    if (resourceType === 'soporte') {
      if (params.idUsuario) {
        if (Number(params.idUsuario) !== user.id) throw new ForbiddenException('Solo puedes ver tu propio soporte.');
      } else if (params.id) {
        const soporte = await this.dataSource.getRepository(Soporte).findOne({ where: { id: Number(params.id) }, relations: { usuario: true } });
        if (!soporte) throw new NotFoundException('Ticket de soporte no encontrado.');
        if (soporte.usuario.id !== user.id) throw new ForbiddenException('No tienes acceso a este ticket de soporte.');
      } else if (body && body.idUsuario) {
        if (Number(body.idUsuario) !== user.id) throw new ForbiddenException('No puedes crear un ticket a nombre de otro usuario.');
      }
    }

    if (resourceType === 'notificacion') {
      if (params.idUsuario) {
        if (Number(params.idUsuario) !== user.id) throw new ForbiddenException('Solo puedes ver tus propias notificaciones.');
      } else if (params.id) {
        const notif = await this.dataSource.getRepository(Notificacion).findOne({ where: { id: Number(params.id) }, relations: { usuario: true } });
        if (!notif) throw new NotFoundException('Notificación no encontrada.');
        if (notif.usuario.id !== user.id) throw new ForbiddenException('No tienes acceso a esta notificación.');
      } else if (body && body.idUsuario) {
        if (Number(body.idUsuario) !== user.id) throw new ForbiddenException('No puedes actuar en nombre de otro usuario.');
      }
    }

    if (resourceType === 'resena') {
      if (params.idUsuario) {
        // GET /resenas/usuario/:idUsuario — solo el propio usuario puede ver sus reseñas
        if (Number(params.idUsuario) !== user.id) throw new ForbiddenException('Solo puedes ver tus propias reseñas.');
      } else if (params.id) {
        const resena = await this.dataSource.getRepository(Resena).findOne({ where: { id: Number(params.id) }, relations: { usuario: true } });
        if (!resena) throw new NotFoundException('Reseña no encontrada.');
        if (resena.usuario.id !== user.id) throw new ForbiddenException('No tienes permisos sobre esta reseña.');
      } else if (body && body.idUsuario) {
        if (Number(body.idUsuario) !== user.id) throw new ForbiddenException('No puedes crear una reseña a nombre de otro usuario.');
      }
    }

    return true;
  }
}
