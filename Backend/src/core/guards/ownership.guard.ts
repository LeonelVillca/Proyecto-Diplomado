import { Injectable, CanActivate, ExecutionContext, ForbiddenException, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { Restaurante } from '../../modules/restaurante/restaurante.entity';
import { Solicitud } from '../../modules/solicitud/solicitud.entity';
import { UsuarioRol } from '../../modules/usuario-rol/usuario-rol.entity';

export const RESOURCE_TYPE_KEY = 'resource_type';
export const CheckOwnership = (
  resource: 'restaurante' | 'menu' | 'plato' | 'mesa' | 'horario_atencion' | 'reserva' | 'resena' | 'visita',
) => SetMetadata(RESOURCE_TYPE_KEY, resource);

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private dataSource: DataSource,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const resourceType = this.reflector.get<string>(RESOURCE_TYPE_KEY, context.getHandler());
    if (!resourceType) return true;

    const req = context.switchToHttp().getRequest();
    const { user, params = {}, body = {} } = req;
    if (!user) return false;

    // Admin_Sistema es el rol global de moderación y no está limitado a un restaurante.
    const rolesDelUsuario = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: user.id },
      relations: { rol: true },
    });
    if (rolesDelUsuario.some((asignacion) => asignacion.rol.nombre === 'admin_sistema')) return true;

    const solicitudesUsuario = await this.dataSource.getRepository(Solicitud).find({
      where: { usuario: { id: user.id }, estado: 'aprobada' },
      select: { id: true },
    });
    const solicitudIds = solicitudesUsuario.map((solicitud) => solicitud.id);
    if (solicitudIds.length === 0) {
      throw new ForbiddenException('El usuario no es dueño de ningún restaurante activo.');
    }

    const restaurantesPropios = await this.dataSource.getRepository(Restaurante)
      .createQueryBuilder('r')
      .where('r.id_solicitud IN (:...solicitudIds)', { solicitudIds })
      .getMany();
    const misRestaurantesIds = restaurantesPropios.map((restaurante) => restaurante.id);
    let targetRestauranteId: number | null = null;

    if (resourceType === 'restaurante') {
      if (params.id) targetRestauranteId = Number(params.id);
    } else if (resourceType === 'reserva') {
      if (params.idRestaurante) targetRestauranteId = Number(params.idRestaurante);
      else if (body.idMesa) {
        const mesa = await this.dataSource.getRepository('Mesa').findOne({ where: { id: Number(body.idMesa) }, relations: { restaurante: true } });
        if (mesa && (mesa as any).restaurante) targetRestauranteId = (mesa as any).restaurante.id;
      } else if (params.id) {
        const reserva = await this.dataSource.getRepository('Reserva').findOne({ where: { id: Number(params.id) }, relations: { mesa: { restaurante: true } } });
        if (reserva && (reserva as any).mesa?.restaurante) targetRestauranteId = (reserva as any).mesa.restaurante.id;
      }
    } else if (resourceType === 'resena') {
      if (body.idResena || params.idResena) {
        const idResena = Number(body.idResena ?? params.idResena);
        const resena = await this.dataSource.getRepository('Resena').findOne({ where: { id: idResena }, relations: { restaurante: true } });
        if (resena && (resena as any).restaurante) targetRestauranteId = (resena as any).restaurante.id;
      } else if (params.id) {
        const respuesta = await this.dataSource.getRepository('RespuestaResena').findOne({ where: { id: Number(params.id) }, relations: { resena: { restaurante: true } } }).catch(() => null);
        if (respuesta && (respuesta as any).resena?.restaurante) targetRestauranteId = (respuesta as any).resena.restaurante.id;
        else {
          const resena = await this.dataSource.getRepository('Resena').findOne({ where: { id: Number(params.id) }, relations: { restaurante: true } }).catch(() => null);
          if (resena && (resena as any).restaurante) targetRestauranteId = (resena as any).restaurante.id;
        }
      }
    } else if (resourceType === 'visita') {
      if (params.idRestaurante) targetRestauranteId = Number(params.idRestaurante);
      else if (body.idRestaurante) targetRestauranteId = Number(body.idRestaurante);
      else if (params.id) {
        const visita = await this.dataSource.getRepository('Visita').findOne({ where: { id: Number(params.id) }, relations: { restaurante: true } });
        if (visita && (visita as any).restaurante) targetRestauranteId = (visita as any).restaurante.id;
      }
    } else {
      if (body.idRestaurante) targetRestauranteId = Number(body.idRestaurante);
      else if (params.idRestaurante) targetRestauranteId = Number(params.idRestaurante);
    }

    if (!targetRestauranteId) throw new ForbiddenException('No se pudo verificar la propiedad del recurso. Acceso denegado.');
    if (!misRestaurantesIds.includes(targetRestauranteId)) throw new ForbiddenException('No tienes permisos para modificar recursos de este restaurante.');
    return true;
  }
}
