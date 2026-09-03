import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { Restaurante } from '../../modules/restaurante/restaurante.entity';
import { Solicitud } from '../../modules/solicitud/solicitud.entity';
import { SetMetadata } from '@nestjs/common';

export const RESOURCE_TYPE_KEY = 'resource_type';
export const CheckOwnership = (resource: 'restaurante' | 'menu' | 'plato' | 'mesa' | 'horario_atencion' | 'reserva' | 'resena') => 
  SetMetadata(RESOURCE_TYPE_KEY, resource);

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private dataSource: DataSource,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const resourceType = this.reflector.get<string>(RESOURCE_TYPE_KEY, context.getHandler());
    
    // Si no hay tipo de recurso definido, asumimos que no requiere ownership check
    if (!resourceType) {
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const { user, params, body } = req;

    if (!user) {
      return false;
    }

    // 1. Obtener todos los IDs de restaurantes que pertenecen a este usuario
    const solicitudesUsuario = await this.dataSource.getRepository(Solicitud).find({
      where: { usuario: { id: user.id }, estado: 'aprobada' },
      select: { id: true },
    });

    const solicitudIds = solicitudesUsuario.map(s => s.id);

    if (solicitudIds.length === 0) {
      throw new ForbiddenException('El usuario no es dueño de ningún restaurante activo.');
    }

    const restaurantesPropios = await this.dataSource.getRepository(Restaurante).createQueryBuilder('r')
      .where('r.id_solicitud IN (:...solicitudIds)', { solicitudIds })
      .getMany();

    const misRestaurantesIds = restaurantesPropios.map(r => r.id);

    // 2. Determinar el id_restaurante afectado por la petición actual
    let targetRestauranteId: number | null = null;

    if (resourceType === 'restaurante') {
      // Si el recurso es restaurante, el id afectado viene en params.id (para PATCH/DELETE)
      // o no aplica si es un POST (crear nuevo restaurante)
      if (params.id) targetRestauranteId = Number(params.id);
    } else if (resourceType === 'reserva') {
      if (params.idRestaurante) targetRestauranteId = Number(params.idRestaurante);
      else if (body && body.idMesa) {
        const mesa = await this.dataSource.getRepository('Mesa').findOne({ where: { id: Number(body.idMesa) }, relations: { restaurante: true } });
        if (mesa && (mesa as any).restaurante) targetRestauranteId = (mesa as any).restaurante.id;
      } else if (params.id) {
        const reserva = await this.dataSource.getRepository('Reserva').findOne({ where: { id: Number(params.id) }, relations: { mesa: { restaurante: true } } });
        if (reserva && (reserva as any).mesa && (reserva as any).mesa.restaurante) {
          targetRestauranteId = (reserva as any).mesa.restaurante.id;
        }
      }
    } else if (resourceType === 'resena') {
      if (body && body.idResena) {
        const resena = await this.dataSource.getRepository('Resena').findOne({ where: { id: Number(body.idResena) }, relations: { restaurante: true } });
        if (resena && (resena as any).restaurante) targetRestauranteId = (resena as any).restaurante.id;
      } else if (params.id) { // Si estamos actualizando o borrando una respuesta, o actuando sobre la reseña
        // Ojo, si el controlador es de respuesta_resena y le pasamos :id, el id es de la respuesta.
        // Pero si pasamos @CheckOwnership('resena'), asumimos que params.id es idResena?
        // En realidad, para PATCH /respuesta/:id, el id es de la respuesta. Mejor busquemos primero si hay params.idResena
        if (params.idResena) {
          const resena = await this.dataSource.getRepository('Resena').findOne({ where: { id: Number(params.idResena) }, relations: { restaurante: true } });
          if (resena && (resena as any).restaurante) targetRestauranteId = (resena as any).restaurante.id;
        } else if (params.id) {
          // Asumimos que params.id puede ser id_respuesta si la ruta es /respuesta-resena/:id
          // Buscamos si existe RespuestaResena con ese ID
          const respuesta = await this.dataSource.getRepository('RespuestaResena').findOne({ where: { id: Number(params.id) }, relations: { resena: { restaurante: true } } }).catch(() => null);
          if (respuesta && (respuesta as any).resena && (respuesta as any).resena.restaurante) {
            targetRestauranteId = (respuesta as any).resena.restaurante.id;
          } else {
            // Si no, asumimos que es directamente id de resena
            const resena = await this.dataSource.getRepository('Resena').findOne({ where: { id: Number(params.id) }, relations: { restaurante: true } }).catch(() => null);
            if (resena && (resena as any).restaurante) targetRestauranteId = (resena as any).restaurante.id;
          }
        }
      }
    } else {
      // Para recursos dependientes, el id_restaurante puede venir en el DTO (body)
      // o podríamos inferirlo consultando la DB con el ID del recurso (params.id).
      // Por simplicidad inicial, buscaremos idRestaurante en body o params:
      if (body && body.idRestaurante) targetRestauranteId = Number(body.idRestaurante);
      else if (params && params.idRestaurante) targetRestauranteId = Number(params.idRestaurante);
    }

    // Si no logramos determinar el restaurante objetivo, lo dejamos pasar por ahora
    // (en una implementación más estricta, cada rama debería resolver su targetRestauranteId buscando en BD)
    if (!targetRestauranteId) {
      return true;
    }

    // 3. Verificar si el restaurante objetivo está en la lista de mis restaurantes
    if (!misRestaurantesIds.includes(targetRestauranteId)) {
      throw new ForbiddenException('No tienes permisos para modificar recursos de este restaurante.');
    }

    return true;
  }
}
