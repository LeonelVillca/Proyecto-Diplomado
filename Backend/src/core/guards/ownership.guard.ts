import { Injectable, CanActivate, ExecutionContext, ForbiddenException, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { Restaurante } from '../../modules/restaurante/restaurante.entity';
import { UsuarioRol } from '../../modules/usuario-rol/usuario-rol.entity';

export const RESOURCE_TYPE_KEY = 'resource_type';
export type OwnedResource = 'restaurante' | 'menu' | 'plato' | 'mesa' | 'horario_atencion' | 'reserva' | 'resena' | 'respuesta_resena' | 'visita' | 'imagen' | 'ubicacion';
export const CheckOwnership = (resource: OwnedResource) => SetMetadata(RESOURCE_TYPE_KEY, resource);

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(private reflector: Reflector, private dataSource: DataSource) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const resource = this.reflector.get<OwnedResource>(RESOURCE_TYPE_KEY, context.getHandler());
    if (!resource) return true;
    const { user, params = {}, body = {} } = context.switchToHttp().getRequest();
    if (!user) return false;
    const roles = await this.dataSource.getRepository(UsuarioRol).find({ where: { idUsuario: user.id }, relations: { rol: true } });
    if (roles.some((r) => r.rol.nombre === 'admin_sistema')) return true;
    const own = await this.dataSource.getRepository(Restaurante).find({
      where: { solicitud: { usuario: { id: user.id }, estado: 'aprobada' } },
      select: { id: true },
    });
    const ownedIds = new Set(own.map((r) => r.id));
    const targets: number[] = [];
    // Primero se comprueba el recurso EXISTENTE. El body nunca reemplaza esta comprobación.
    if (params.id !== undefined) targets.push(...await this.restaurantIds(resource, params.id));
    if (params.idRestaurante !== undefined) targets.push(this.validId(params.idRestaurante));
    if (params.idPlato !== undefined) targets.push(...await this.restaurantIds('plato', params.idPlato));
    if (params.idResena !== undefined) targets.push(...await this.restaurantIds('resena', params.idResena));
    for (const [field, kind] of Object.entries({ idRestaurante: 'restaurante', idMenu: 'menu', idMesa: 'mesa', idPlato: 'plato', idResena: 'resena' })) {
      if (body[field] !== undefined) targets.push(...await this.restaurantIds(kind as OwnedResource, body[field]));
    }
    if (!targets.length || targets.some((id) => !ownedIds.has(id))) {
      throw new ForbiddenException('No tienes permisos sobre este recurso o su restaurante de destino');
    }
    return true;
  }

  private validId(value: unknown): number {
    if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(Number(value)) || Number(value) <= 0) {
      throw new ForbiddenException('Identificador de recurso inválido');
    }
    return Number(value);
  }

  private async restaurantIds(type: OwnedResource, value: unknown): Promise<number[]> {
    const id = this.validId(value);
    if (type === 'restaurante') return [id];
    const config: Record<string, [string, any]> = {
      menu: ['Menu', { restaurante: true }], mesa: ['Mesa', { restaurante: true }],
      horario_atencion: ['HorarioAtencion', { restaurante: true }], ubicacion: ['Ubicacion', { restaurante: true }],
      visita: ['Visita', { restaurante: true }], resena: ['Resena', { restaurante: true }],
      plato: ['Plato', { menu: { restaurante: true } }], reserva: ['Reserva', { mesa: { restaurante: true } }],
      respuesta_resena: ['RespuestaResena', { resena: { restaurante: true } }],
      imagen: ['Imagen', { restaurante: true, plato: { menu: { restaurante: true } } }],
    };
    const [entity, relations] = config[type];
    const record: any = await this.dataSource.getRepository(entity).findOne({ where: { id }, relations });
    const ids = [record?.restaurante?.id, record?.menu?.restaurante?.id, record?.mesa?.restaurante?.id,
      record?.resena?.restaurante?.id, record?.plato?.menu?.restaurante?.id].filter((v) => v !== undefined);
    if (!ids.length) throw new ForbiddenException('No se pudo verificar el recurso');
    return ids;
  }
}
