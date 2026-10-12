import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { Restaurante } from '../restaurante.entity';
import { HorarioAtencion } from '../../horario-atencion/horario-atencion.entity';
import { Mesa } from '../../mesa/mesa.entity';
import { TipoComida } from '../tipo-comida.entity';

export type DatosPublicacion = Restaurante & {
  direccion?: string | null;
  latitud?: number | null;
  longitud?: number | null;
  horarios: HorarioAtencion[];
  mesas: Mesa[];
  tiposComida: TipoComida[];
};

@Injectable()
export class PublicacionRestauranteService {
  // Comprueba si el perfil puede publicarse.
  perfilPublicable(restaurante: DatosPublicacion): boolean {
    return restaurante.estado === true && this.perfilCompleto(restaurante);
  }

  // Comprueba si el perfil contiene los datos requeridos.
  perfilCompleto(restaurante: DatosPublicacion): boolean {
    const textoCompleto = (valor: unknown) =>
      typeof valor === 'string' && valor.trim().length > 0;
    const solicitudAprobada =
      !restaurante.solicitud || restaurante.solicitud.estado === 'aprobada';

    return (
      solicitudAprobada &&
      textoCompleto(restaurante.nombre) &&
      ((Array.isArray(restaurante.tiposComida) &&
        restaurante.tiposComida.length > 0) ||
        textoCompleto(restaurante.tipoComida)) &&
      textoCompleto(restaurante.descripcion) &&
      textoCompleto(restaurante.telefono) &&
      textoCompleto(restaurante.correo) &&
      textoCompleto(restaurante.fotoPortada) &&
      textoCompleto(restaurante.logo) &&
      textoCompleto(restaurante.direccion) &&
      restaurante.latitud !== null &&
      restaurante.latitud !== undefined &&
      restaurante.longitud !== null &&
      restaurante.longitud !== undefined &&
      Array.isArray(restaurante.horarios) &&
      restaurante.horarios.length > 0 &&
      Array.isArray(restaurante.mesas) &&
      restaurante.mesas.length > 0
    );
  }

  // Activa el restaurante cuando su perfil está completo.
  async activarSiPerfilCompleto(
    id: number,
    estabaCompleto: boolean,
    datos: DatosPublicacion | null,
    manager: EntityManager,
  ): Promise<void> {
    // Un perfil previamente completo pudo haber sido suspendido por un administrador.
    if (estabaCompleto || !datos || datos.estado === true) return;
    if (this.perfilCompleto(datos)) {
      await manager
        .getRepository(Restaurante)
        .update({ id, estado: false }, { estado: true });
    }
  }
}
