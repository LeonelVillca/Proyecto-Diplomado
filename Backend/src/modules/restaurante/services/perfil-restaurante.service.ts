import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { sanitizeImage } from '../../../core/security/uploads';
import { PublicImageStorageService } from '../../../core/storage/public-image-storage.service';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Restaurante } from '../restaurante.entity';
import { CrearRestauranteDto } from '../dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from '../dto/actualizar-restaurante.dto';
import { Solicitud } from '../../solicitud/solicitud.entity';
import { Ubicacion } from '../../ubicacion/ubicacion.entity';
import { HorarioAtencionService } from '../../horario-atencion/horario-atencion.service';
import { Mesa } from '../../mesa/mesa.entity';
import { Imagen } from '../../imagen/imagen.entity';
import { UsuarioRestaurante } from '../../usuario-restaurante/usuario-restaurante.entity';
import { TipoComida } from '../tipo-comida.entity';
import { PublicacionRestauranteService } from './publicacion-restaurante.service';
import { RestauranteConsultasService } from '../queries/restaurante-consultas.service';

@Injectable()
export class PerfilRestauranteService {
  constructor(
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Imagen)
    private readonly imagenRepository: Repository<Imagen>,
    @InjectRepository(UsuarioRestaurante)
    private readonly usuarioRestauranteRepository: Repository<UsuarioRestaurante>,
    private readonly images: PublicImageStorageService,
    private readonly consultas: RestauranteConsultasService,
    private readonly publicacion: PublicacionRestauranteService,
    private readonly horarioService: HorarioAtencionService,
  ) {}

  async crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.restauranteRepository.manager.transaction(async (manager) => {
      let solicitud: Solicitud | null = null;
      if (dto.idSolicitud !== undefined) {
        solicitud = await manager.findOne(Solicitud, {
          where: { id: dto.idSolicitud },
          relations: { usuario: true },
        });
        if (!solicitud) {
          throw new NotFoundException(
            `Solicitud con id ${dto.idSolicitud} no encontrada`,
          );
        }
      }

      const { idSolicitud, tiposComidaIds, ...datos } = dto;
      const tiposComida = tiposComidaIds?.length
        ? await manager.find(TipoComida, {
            where: { id: In(tiposComidaIds), activo: true },
          })
        : [];
      if (tiposComidaIds && tiposComida.length !== tiposComidaIds.length) {
        throw new BadRequestException('Uno o más tipos de comida no existen');
      }
      const guardado = await manager.save(
        manager.create(Restaurante, {
          ...datos,
          tipoComida: tiposComida[0]?.nombre ?? datos.tipoComida,
          tiposComida,
          solicitud: idSolicitud ? { id: idSolicitud } : null,
          estado: false,
        }),
      );
      if (solicitud?.usuario) {
        await manager.save(
          manager.create(UsuarioRestaurante, {
            usuario: { id: solicitud.usuario.id },
            restaurante: { id: guardado.id },
            rol: 'propietario',
            activo: true,
          }),
        );
      }
      return guardado;
    });
  }

  async cambiarEstadoComoAdministrador(
    id: number,
    estado: boolean,
  ): Promise<any> {
    if (estado === true) {
      const datos = await this.consultas.datosParaPublicacion(id);
      if (!datos || !this.publicacion.perfilCompleto(datos)) {
        throw new BadRequestException(
          'Completa la ubicación, horarios, mesas y datos del perfil antes de activar el restaurante.',
        );
      }
    }
    const restaurante = await this.buscarPorId(id);
    restaurante.estado = estado;
    const actualizado = await this.restauranteRepository.save(restaurante);
    return {
      id: actualizado.id,
      nombre: actualizado.nombre,
      estado: actualizado.estado,
    };
  }

  private async activarSiPerfilCompleto(
    id: number,
    estabaCompleto: boolean,
  ): Promise<void> {
    const datos = await this.consultas.datosParaPublicacion(id);
    await this.publicacion.activarSiPerfilCompleto(
      id,
      estabaCompleto,
      datos,
      this.restauranteRepository.manager,
    );
  }

  async listarPorUsuario(idUsuario: number): Promise<any[]> {
    let asignaciones = await this.usuarioRestauranteRepository.find({
      where: { idUsuario, activo: true },
    });
    let ids = asignaciones.map((item) => item.idRestaurante);
    const perfiles = await this.consultas.listarPorIds(ids);
    if (perfiles.length) return perfiles;
    await this.asegurarRestauranteDeSolicitud(idUsuario);
    asignaciones = await this.usuarioRestauranteRepository.find({
      where: { idUsuario, activo: true },
    });
    ids = asignaciones.map((item) => item.idRestaurante);
    return this.consultas.listarPorIds(ids);
  }

  private async asegurarRestauranteDeSolicitud(
    idUsuario: number,
  ): Promise<void> {
    await this.restauranteRepository.manager.transaction(async (manager) => {
      // Serializa las reparaciones concurrentes del mismo usuario.
      await manager.query(
        'SELECT id_usuario FROM usuarios WHERE id_usuario = $1 FOR UPDATE',
        [idUsuario],
      );
      const asignaciones = await manager.find(UsuarioRestaurante, {
        where: { idUsuario, activo: true },
      });
      if (
        asignaciones.length &&
        (await manager.count(Restaurante, {
          where: { id: In(asignaciones.map((item) => item.idRestaurante)) },
        })) > 0
      )
        return;

      const solicitud = await manager.findOne(Solicitud, {
        where: { usuario: { id: idUsuario }, estado: 'aprobada' },
        relations: { usuario: true },
      });
      if (!solicitud) return;

      let restaurante = await manager.findOne(Restaurante, {
        where: { solicitud: { id: solicitud.id } },
      });
      if (!restaurante) {
        restaurante = await manager.save(
          manager.create(Restaurante, {
            solicitud: { id: solicitud.id },
            nombre: solicitud.nombreRestaurante,
            tipoComida: solicitud.tipoComida,
            descripcion: solicitud.descripcion,
            telefono: solicitud.celularContacto,
            correo: solicitud.usuario.correo,
            estado: false,
          }),
        );
      }
      const asignacion = await manager.findOne(UsuarioRestaurante, {
        where: { idUsuario, idRestaurante: restaurante.id },
      });
      // Una asignación revocada nunca se reactiva por consultar el perfil.
      if (asignacion) return;
      await manager.save(
        manager.create(UsuarioRestaurante, {
          usuario: { id: idUsuario },
          restaurante: { id: restaurante.id },
          rol: 'propietario',
          activo: true,
        }),
      );
    });
  }

  buscarPorId(id: number): Promise<Restaurante> {
    return this.consultas.buscarPorId(id);
  }

  async actualizar(
    id: number,
    dto: ActualizarRestauranteDto,
  ): Promise<Restaurante> {
    const defineMesas = dto.mesasTotal !== undefined;
    const defineCapacidad = dto.capacidadTotal !== undefined;
    if (defineMesas !== defineCapacidad) {
      throw new BadRequestException(
        'mesasTotal y capacidadTotal deben enviarse juntos',
      );
    }
    if (
      dto.mesasTotal !== undefined &&
      dto.capacidadTotal !== undefined &&
      dto.capacidadTotal < dto.mesasTotal
    ) {
      throw new BadRequestException(
        'capacidadTotal debe ser mayor o igual que mesasTotal',
      );
    }

    await this.restauranteRepository.manager.transaction(async (manager) => {
      await manager.query(
        'SELECT id_restaurante FROM restaurante WHERE id_restaurante = $1 FOR UPDATE',
        [id],
      );
      const restaurante = await manager.findOne(Restaurante, { where: { id } });
      if (!restaurante) {
        throw new NotFoundException(`Restaurante con id ${id} no encontrado`);
      }
      const perfilAnterior = await this.consultas.datosParaPublicacion(
        id,
        manager,
      );
      const estabaCompleto = perfilAnterior
        ? this.publicacion.perfilCompleto(perfilAnterior)
        : false;

      const {
        direccion,
        latitud,
        longitud,
        horarios,
        mesasTotal,
        capacidadTotal,
        tiposComidaIds,
        ...datos
      } = dto;
      Object.assign(restaurante, datos);
      if (tiposComidaIds !== undefined) {
        const tiposComida = tiposComidaIds.length
          ? await manager.find(TipoComida, {
              where: { id: In(tiposComidaIds), activo: true },
            })
          : [];
        if (tiposComida.length !== tiposComidaIds.length) {
          throw new BadRequestException('Uno o más tipos de comida no existen');
        }
        restaurante.tiposComida = tiposComida;
        restaurante.tipoComida = tiposComida[0]?.nombre ?? null;
      }
      await manager.save(restaurante);

      const ubicaciones = manager.getRepository(Ubicacion);
      if (
        direccion !== undefined ||
        latitud !== undefined ||
        longitud !== undefined
      ) {
        let ubicacion = await ubicaciones.findOne({
          where: { restaurante: { id } },
        });
        if (!ubicacion) ubicacion = ubicaciones.create({ restaurante: { id } });
        if (direccion !== undefined) ubicacion.direccion = direccion;
        if (latitud !== undefined) ubicacion.latitud = latitud;
        if (longitud !== undefined) ubicacion.longitud = longitud;
        await ubicaciones.save(ubicacion);
      }

      if (horarios !== undefined) {
        await this.horarioService.reemplazarSemanales(manager, id, horarios);
      }

      if (mesasTotal !== undefined && capacidadTotal !== undefined) {
        const mesasRepo = manager.getRepository(Mesa);
        const mesasActuales = await mesasRepo.count({
          where: { restaurante: { id } },
        });
        if (mesasActuales === 0 && mesasTotal > 0) {
          const capacidadPorMesa = Math.floor(capacidadTotal / mesasTotal);
          await mesasRepo.save(
            Array.from({ length: mesasTotal }, (_, indice) =>
              mesasRepo.create({
                restaurante: { id },
                numeroMesa: `Mesa ${indice + 1}`,
                capacidad: capacidadPorMesa,
                estado: 'libre',
              }),
            ),
          );
        }
      }
      const perfilActual = await this.consultas.datosParaPublicacion(
        id,
        manager,
      );
      await this.publicacion.activarSiPerfilCompleto(
        id,
        estabaCompleto,
        perfilActual,
        manager,
      );
    });

    return this.buscarPorId(id);
  }

  async eliminar(id: number): Promise<void> {
    const restaurante = await this.buscarPorId(id);
    restaurante.estado = false;
    await this.restauranteRepository.save(restaurante);
    await this.restauranteRepository.softRemove(restaurante);
  }

  async subirPortada(
    id: number,
    file: Express.Multer.File,
  ): Promise<Restaurante> {
    if (!file)
      throw new BadRequestException('Se requiere una imagen de portada');

    const restaurante = await this.buscarPorId(id);
    const perfilAnterior = await this.consultas.datosParaPublicacion(id);
    const estabaCompleto = perfilAnterior
      ? this.publicacion.perfilCompleto(perfilAnterior)
      : false;

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('El archivo debe ser una imagen');
    }

    restaurante.fotoPortada = await this.images.uploadWebp(
      await sanitizeImage(file),
      id,
      'portada',
    );
    const guardado = await this.restauranteRepository.save(restaurante);
    await this.activarSiPerfilCompleto(id, estabaCompleto);
    return guardado;
  }

  async subirLogo(id: number, file: Express.Multer.File): Promise<Restaurante> {
    if (!file) throw new BadRequestException('Se requiere una imagen de logo');

    const restaurante = await this.buscarPorId(id);
    const perfilAnterior = await this.consultas.datosParaPublicacion(id);
    const estabaCompleto = perfilAnterior
      ? this.publicacion.perfilCompleto(perfilAnterior)
      : false;

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('El archivo debe ser una imagen');
    }

    restaurante.logo = await this.images.uploadWebp(
      await sanitizeImage(file),
      id,
      'logo',
    );
    const guardado = await this.restauranteRepository.save(restaurante);
    await this.activarSiPerfilCompleto(id, estabaCompleto);
    return guardado;
  }

  async subirGaleria(
    id: number,
    files: Express.Multer.File[],
  ): Promise<Restaurante> {
    if (!files || files.length === 0)
      throw new BadRequestException('Se requieren imágenes para la galería');

    const restaurante = await this.buscarPorId(id);
    const count = await this.imagenRepository.count({
      where: { restaurante: { id } },
    });
    if (count + files.length > 50)
      throw new BadRequestException('La galería admite hasta 50 imágenes');
    const nuevasImagenes: Imagen[] = [];
    for (const file of files) {
      if (!file.mimetype.startsWith('image/'))
        throw new BadRequestException('Los archivos deben ser imágenes');
      const url = await this.images.uploadWebp(
        await sanitizeImage(file),
        id,
        'galeria',
      );

      nuevasImagenes.push(
        this.imagenRepository.create({
          restaurante: { id: restaurante.id },
          url,
        }),
      );
    }

    await this.imagenRepository.save(nuevasImagenes);
    return restaurante;
  }
}
