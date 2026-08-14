import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UsuarioRol } from '../../modules/usuario-rol/usuario-rol.entity';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private dataSource: DataSource,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();

    if (!user) {
      return false;
    }

    // Buscamos los roles del usuario directamente por base de datos
    const usuarioRoles = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: user.id },
      relations: { rol: true },
    });

    const userRoleNames = usuarioRoles.map((ur) => ur.rol.nombre);

    // Verificamos si el usuario tiene al menos uno de los roles requeridos
    return requiredRoles.some((role) => userRoleNames.includes(role));
  }
}
