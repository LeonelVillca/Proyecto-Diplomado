import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, In, Repository } from 'typeorm';
import { Restaurante } from '../restaurante.entity';
import { TipoComida } from '../tipo-comida.entity';
import { Ubicacion } from '../../ubicacion/ubicacion.entity';
import { HorarioAtencion } from '../../horario-atencion/horario-atencion.entity';
import { Mesa } from '../../mesa/mesa.entity';
import { Imagen } from '../../imagen/imagen.entity';
import { Resena } from '../../resenas/resena.entity';
import {
  DatosPublicacion,
  PublicacionRestauranteService,
} from '../services/publicacion-restaurante.service';

export type PerfilRestauranteRespuesta = DatosPublicacion & {
  imagenes: Imagen[];
  rating: number;
  reviewCount: number;
};

@Injectable()
export class RestauranteConsultasService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    @InjectRepository(Restaurante)
    private readonly restaurantes: Repository<Restaurante>,
    @InjectRepository(Ubicacion)
    private readonly ubicaciones: Repository<Ubicacion>,
    @InjectRepository(HorarioAtencion)
    private readonly horarios: Repository<HorarioAtencion>,
    @InjectRepository(Mesa)
    private readonly mesas: Repository<Mesa>,
    @InjectRepository(Imagen)
    private readonly imagenes: Repository<Imagen>,
    @InjectRepository(Resena)
    private readonly resenas: Repository<Resena>,
    private readonly publicacion: PublicacionRestauranteService,
  ) {}

  // Añade datos complementarios a varios restaurantes.
  private async enriquecerMuchos(
    restaurantes: Restaurante[],
  ): Promise<PerfilRestauranteRespuesta[]> {
    if (!restaurantes.length) return [];
    const ids = restaurantes.map((restaurante) => restaurante.id);
    const where = { restaurante: { id: In(ids) } };
    const [ubicaciones, horarios, mesas, imagenes, resenas] = await Promise.all(
      [
        this.ubicaciones.find({ where, relations: { restaurante: true } }),
        this.horarios.find({ where, relations: { restaurante: true } }),
        this.mesas.find({ where, relations: { restaurante: true } }),
        this.imagenes.find({ where, relations: { restaurante: true } }),
        this.resenas.find({ where, relations: { restaurante: true } }),
      ],
    );
    const agrupar = <T extends { restaurante: Restaurante }>(
      items: T[],
    ): Map<number, T[]> => {
      const grouped = new Map<number, T[]>();
      for (const item of items) {
        const id = item.restaurante.id;
        // La relacion solo identifica el grupo; no forma parte del contrato de salida.
        delete (item as Partial<T>).restaurante;
        const group = grouped.get(id) ?? [];
        group.push(item);
        grouped.set(id, group);
      }
      return grouped;
    };
    const ubicacionesPorRestaurante = agrupar(ubicaciones);
    const horariosPorRestaurante = agrupar(horarios);
    const mesasPorRestaurante = agrupar(mesas);
    const imagenesPorRestaurante = agrupar(imagenes);
    const resenasPorRestaurante = agrupar(resenas);
    return restaurantes.map((restaurante) => {
      const id = restaurante.id;
      const ubicacion = ubicacionesPorRestaurante.get(id)?.[0];
      const resenasRestaurante = resenasPorRestaurante.get(id) ?? [];
      const reviewCount = resenasRestaurante.length;
      const rating = reviewCount
        ? parseFloat(
            (
              resenasRestaurante.reduce(
                (total, resena) => total + resena.calificacion,
                0,
              ) / reviewCount
            ).toFixed(1),
          )
        : 0;
      return {
        ...restaurante,
        direccion: ubicacion?.direccion,
        latitud: ubicacion?.latitud,
        longitud: ubicacion?.longitud,
        horarios: horariosPorRestaurante.get(id) ?? [],
        mesas: mesasPorRestaurante.get(id) ?? [],
        imagenes: imagenesPorRestaurante.get(id) ?? [],
        rating,
        reviewCount,
      };
    });
  }

  // Lista los restaurantes.
  async listarTodos(): Promise<PerfilRestauranteRespuesta[]> {
    const restaurantes = await this.restaurantes.find({
      relations: { solicitud: true, tiposComida: true },
    });
    const perfiles = await this.enriquecerMuchos(restaurantes);
    return perfiles.filter((perfil) =>
      this.publicacion.perfilPublicable(perfil),
    );
  }

  // Lista restaurantes a partir de sus identificadores.
  async listarPorIds(ids: number[]): Promise<PerfilRestauranteRespuesta[]> {
    if (!ids.length) return [];
    const restaurantes = await this.restaurantes.find({
      where: { id: In(ids) },
      relations: { solicitud: { usuario: true }, tiposComida: true },
    });
    return this.enriquecerMuchos(restaurantes);
  }

  // Lista restaurantes para la administración del sistema.
  async listarParaAdministrador(): Promise<any[]> {
    const restaurantes = await this.restaurantes.find({
      relations: { solicitud: { usuario: true }, tiposComida: true },
      order: { id: 'DESC' },
    });
    return restaurantes.map((restaurante) => ({
      id: restaurante.id,
      nombre: restaurante.nombre,
      tipoComida: restaurante.tipoComida,
      tiposComida: restaurante.tiposComida ?? [],
      descripcion: restaurante.descripcion,
      telefono: restaurante.telefono,
      correo: restaurante.correo,
      fotoPortada: restaurante.fotoPortada,
      logo: restaurante.logo,
      estado: restaurante.estado,
      solicitudEstado: restaurante.solicitud?.estado ?? null,
      administrador: restaurante.solicitud?.usuario
        ? {
            id: restaurante.solicitud.usuario.id,
            nombre: restaurante.solicitud.usuario.nombre,
            apellido: restaurante.solicitud.usuario.apellido,
            correo: restaurante.solicitud.usuario.correo,
          }
        : null,
    }));
  }

  // Busca un restaurante por su identificador.
  async buscarPorId(id: number): Promise<Restaurante> {
    const restaurante = await this.restaurantes.findOne({
      where: { id },
      relations: { solicitud: true, tiposComida: true },
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${id} no encontrado`);
    }
    return restaurante;
  }

  // Busca un restaurante visible para el público.
  async buscarPorIdPublico(id: number): Promise<Restaurante> {
    const restaurante = await this.buscarPorId(id);
    const datos = await this.datosParaPublicacion(id);
    if (!datos || !this.publicacion.perfilPublicable(datos)) {
      throw new NotFoundException(`Restaurante con id ${id} no disponible`);
    }
    return restaurante;
  }

  // Reúne los datos necesarios para publicar un restaurante.
  async datosParaPublicacion(
    id: number,
    manager: EntityManager = this.restaurantes.manager,
  ): Promise<DatosPublicacion | null> {
    const restaurante = await manager.getRepository(Restaurante).findOne({
      where: { id },
      relations: { solicitud: true, tiposComida: true },
    });
    if (!restaurante) return null;
    // En una transacción, el EntityManager comparte una sola conexión.
    const ubicacion = await manager.getRepository(Ubicacion).findOne({
      where: { restaurante: { id } },
    });
    const horarios = await manager.getRepository(HorarioAtencion).find({
      where: { restaurante: { id } },
    });
    const mesas = await manager.getRepository(Mesa).find({
      where: { restaurante: { id } },
    });
    return {
      ...restaurante,
      direccion: ubicacion?.direccion,
      latitud: ubicacion?.latitud,
      longitud: ubicacion?.longitud,
      horarios,
      mesas,
    };
  }

  // Obtiene el ranking de restaurantes.
  async obtenerRanking(limite = 10): Promise<PerfilRestauranteRespuesta[]> {
    const todos = await this.listarTodos();
    const limiteSeguro = Number.isFinite(limite)
      ? Math.min(Math.max(Math.trunc(limite), 1), 50)
      : 10;
    return todos
      .sort((a, b) => Number(b.rating ?? 0) - Number(a.rating ?? 0))
      .slice(0, limiteSeguro);
  }

  // Lista los tipos de comida disponibles.
  listarTiposComida(): Promise<TipoComida[]> {
    return this.restaurantes.manager.find(TipoComida, {
      where: { activo: true },
      order: { nombre: 'ASC' },
    });
  }
}
