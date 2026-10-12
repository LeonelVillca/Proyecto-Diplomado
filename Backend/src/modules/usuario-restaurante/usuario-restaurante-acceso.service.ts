import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { UsuarioRestaurante } from './usuario-restaurante.entity';

export interface AccesoRestaurante {
  adminSistema: boolean;
  adminRestaurante: boolean;
  restaurantesAsignados: Set<number>;
}

@Injectable()
export class UsuarioRestauranteAccesoService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly dataSource: DataSource) {}

  // Obtiene el acceso de un usuario a un restaurante.
  async obtenerAcceso(idUsuario: number): Promise<AccesoRestaurante> {
    const [roles, asignaciones] = await Promise.all([
      this.dataSource.getRepository(UsuarioRol).find({
        where: { idUsuario },
        relations: { rol: true },
      }),
      this.dataSource.getRepository(UsuarioRestaurante).find({
        where: { idUsuario, activo: true },
      }),
    ]);
    const nombres = new Set(roles.map((asignacion) => asignacion.rol.nombre));
    return {
      adminSistema: nombres.has('admin_sistema'),
      adminRestaurante: nombres.has('admin_restaurante'),
      restaurantesAsignados: new Set(
        asignaciones.map((asignacion) => asignacion.idRestaurante),
      ),
    };
  }

  // Comprueba si un usuario puede administrar el restaurante.
  puedeAdministrar(acceso: AccesoRestaurante, idRestaurante: number): boolean {
    return (
      acceso.adminSistema ||
      (acceso.adminRestaurante &&
        acceso.restaurantesAsignados.has(idRestaurante))
    );
  }
}
