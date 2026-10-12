import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { UsuarioRestauranteAccesoService } from '../../modules/usuario-restaurante/usuario-restaurante-acceso.service';

export const RESOURCE_TYPE_KEY = 'resource_type';
export type OwnedResource =
  | 'restaurante'
  | 'menu'
  | 'plato'
  | 'mesa'
  | 'horario_atencion'
  | 'excepcion_horario'
  | 'reserva'
  | 'resena'
  | 'respuesta_resena'
  | 'imagen'
  | 'ubicacion';
export const CheckOwnership = (resource: OwnedResource) =>
  SetMetadata(RESOURCE_TYPE_KEY, resource);

@Injectable()
export class OwnershipGuard implements CanActivate {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    private reflector: Reflector,
    private dataSource: DataSource,
    private readonly accesoRestaurante: UsuarioRestauranteAccesoService,
  ) {}

  // Comprueba si la solicitud tiene acceso a este recurso.
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const resource = this.reflector.get<OwnedResource>(
      RESOURCE_TYPE_KEY,
      context.getHandler(),
    );
    if (!resource) return true;
    const {
      user,
      params = {},
      body = {},
    } = context.switchToHttp().getRequest();
    if (!user) return false;
    const acceso = await this.accesoRestaurante.obtenerAcceso(user.id);
    if (acceso.adminSistema) return true;
    const targets: number[] = [];
    // Primero se comprueba el recurso EXISTENTE. El body nunca reemplaza esta comprobación.
    if (params.id !== undefined)
      targets.push(...(await this.restaurantIds(resource, params.id)));
    if (params.idRestaurante !== undefined)
      targets.push(this.validId(params.idRestaurante));
    if (params.idPlato !== undefined)
      targets.push(...(await this.restaurantIds('plato', params.idPlato)));
    if (params.idResena !== undefined)
      targets.push(...(await this.restaurantIds('resena', params.idResena)));
    for (const [field, kind] of Object.entries({
      idRestaurante: 'restaurante',
      idMenu: 'menu',
      idMesa: 'mesa',
      idPlato: 'plato',
      idResena: 'resena',
    })) {
      if (body[field] !== undefined)
        targets.push(
          ...(await this.restaurantIds(kind as OwnedResource, body[field])),
        );
    }
    if (
      !targets.length ||
      targets.some((id) => !this.accesoRestaurante.puedeAdministrar(acceso, id))
    ) {
      throw new ForbiddenException(
        'No tienes permisos sobre este recurso o su restaurante de destino',
      );
    }
    return true;
  }

  // Valida el identificador recibido en la solicitud.
  private validId(value: unknown): number {
    if (
      !/^\d+$/.test(String(value)) ||
      !Number.isSafeInteger(Number(value)) ||
      Number(value) <= 0
    ) {
      throw new ForbiddenException('Identificador de recurso inválido');
    }
    return Number(value);
  }

  // Obtiene los restaurantes que administra el usuario.
  private async restaurantIds(
    type: OwnedResource,
    value: unknown,
  ): Promise<number[]> {
    const id = this.validId(value);
    if (type === 'restaurante') return [id];
    const config: Record<string, [string, any]> = {
      menu: ['Menu', { restaurante: true }],
      mesa: ['Mesa', { restaurante: true }],
      horario_atencion: ['HorarioAtencion', { restaurante: true }],
      excepcion_horario: ['ExcepcionHorario', { restaurante: true }],
      ubicacion: ['Ubicacion', { restaurante: true }],
      resena: ['Resena', { restaurante: true }],
      plato: ['Plato', { menu: { restaurante: true } }],
      reserva: ['Reserva', { mesa: { restaurante: true } }],
      respuesta_resena: ['RespuestaResena', { resena: { restaurante: true } }],
      imagen: ['Imagen', { restaurante: true }],
    };
    const [entity, relations] = config[type];
    const record: any = await this.dataSource
      .getRepository(entity)
      .findOne({ where: { id }, relations });
    const ids = [
      record?.restaurante?.id,
      record?.menu?.restaurante?.id,
      record?.mesa?.restaurante?.id,
      record?.resena?.restaurante?.id,
    ].filter((v) => v !== undefined);
    if (!ids.length)
      throw new ForbiddenException('No se pudo verificar el recurso');
    return ids;
  }
}
