import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
import { sanitizeImage } from '../../core/security/uploads';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Restaurante } from './restaurante.entity';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { Solicitud } from '../solicitud/solicitud.entity';
import { Ubicacion } from '../ubicacion/ubicacion.entity';
import { HorarioAtencion } from '../horario-atencion/horario-atencion.entity';
import { Mesa } from '../mesa/mesa.entity';
import { Imagen } from '../imagen/imagen.entity';
import { Resena } from '../resenas/resena.entity';

@Injectable()
export class RestauranteService {
  constructor(
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Solicitud)
    private readonly solicitudRepository: Repository<Solicitud>,
    @InjectRepository(Ubicacion)
    private readonly ubicacionRepository: Repository<Ubicacion>,
    @InjectRepository(HorarioAtencion)
    private readonly horarioRepository: Repository<HorarioAtencion>,
    @InjectRepository(Mesa)
    private readonly mesaRepository: Repository<Mesa>,
    @InjectRepository(Imagen)
    private readonly imagenRepository: Repository<Imagen>,
    @InjectRepository(Resena)
    private readonly resenaRepository: Repository<Resena>,
  ) {}

  async crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    if (dto.idSolicitud !== undefined) {
      const solicitud = await this.solicitudRepository.findOneBy({
        id: dto.idSolicitud,
      });
      if (!solicitud) {
        throw new NotFoundException(
          `Solicitud con id ${dto.idSolicitud} no encontrada`,
        );
      }
    }

    const { idSolicitud, ...datos } = dto;
    const restaurante = this.restauranteRepository.create({
      ...datos,
      solicitud: idSolicitud ? { id: idSolicitud } : null,
      estado: false,
    });
    return this.restauranteRepository.save(restaurante);
  }

  async listarTodos(): Promise<any[]> {
    const restaurantes = await this.restauranteRepository.find({
      relations: { solicitud: true },
    });

    // Adjuntar la ubicación e imágenes al resultado para el frontend móvil
    const restaurantesCompletos = await Promise.all(
      restaurantes.map(async (rest) => {
        const ubicacion = await this.ubicacionRepository.findOne({
          where: { restaurante: { id: rest.id } },
        });
        const horarios = await this.horarioRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        const mesas = await this.mesaRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        const imagenes = await this.imagenRepository.find({
          where: { restaurante: { id: rest.id } },
        });

        // Calcular reseñas
        const resenas = await this.resenaRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        let rating = 0;
        let reviewCount = resenas.length;
        if (reviewCount > 0) {
          const totalScore = resenas.reduce(
            (sum, r) => sum + r.calificacion,
            0,
          );
          rating = parseFloat((totalScore / reviewCount).toFixed(1));
        }

        return {
          ...rest,
          direccion: ubicacion?.direccion,
          latitud: ubicacion?.latitud,
          longitud: ubicacion?.longitud,
          horarios,
          mesas,
          imagenes,
          rating,
          reviewCount,
        };
      }),
    );
    // Los perfiles incompletos solo deben estar disponibles para su administrador.
    return restaurantesCompletos.filter((rest) => this.perfilPublicable(rest));
  }

  async listarParaAdministrador(): Promise<any[]> {
    const restaurantes = await this.restauranteRepository.find({
      relations: { solicitud: { usuario: true } },
      order: { id: 'DESC' },
    });

    return restaurantes.map((restaurante) => ({
      id: restaurante.id,
      nombre: restaurante.nombre,
      tipoComida: restaurante.tipoComida,
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

  async cambiarEstadoComoAdministrador(
    id: number,
    estado: boolean,
  ): Promise<any> {
    const restaurante = await this.buscarPorId(id);
    restaurante.estado = estado;
    const actualizado = await this.restauranteRepository.save(restaurante);
    return {
      id: actualizado.id,
      nombre: actualizado.nombre,
      estado: actualizado.estado,
    };
  }

  private perfilPublicable(restaurante: any): boolean {
    const textoCompleto = (valor: unknown) =>
      typeof valor === 'string' && valor.trim().length > 0;
    const solicitudAprobada =
      !restaurante.solicitud || restaurante.solicitud.estado === 'aprobada';

    return (
      restaurante.estado === true &&
      solicitudAprobada &&
      textoCompleto(restaurante.nombre) &&
      textoCompleto(restaurante.tipoComida) &&
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

  private async activarSiPerfilCompleto(id: number): Promise<void> {
    const restaurante = await this.restauranteRepository.findOne({
      where: { id },
      relations: { solicitud: true },
    });
    if (!restaurante || restaurante.estado === true) return;

    const ubicacion = await this.ubicacionRepository.findOne({
      where: { restaurante: { id } },
    });
    const horarios = await this.horarioRepository.find({
      where: { restaurante: { id } },
    });
    const mesas = await this.mesaRepository.find({
      where: { restaurante: { id } },
    });
    const publicable = this.perfilPublicable({
      ...restaurante,
      direccion: ubicacion?.direccion,
      latitud: ubicacion?.latitud,
      longitud: ubicacion?.longitud,
      horarios,
      mesas,
    });

    if (publicable) {
      restaurante.estado = true;
      await this.restauranteRepository.save(restaurante);
    }
  }

  async obtenerRanking(limite = 10): Promise<any[]> {
    const todos = await this.listarTodos();
    const limiteSeguro = Number.isFinite(limite)
      ? Math.min(Math.max(Math.trunc(limite), 1), 50)
      : 10;
    return todos
      .sort((a, b) => Number(b.rating ?? 0) - Number(a.rating ?? 0))
      .slice(0, limiteSeguro);
  }

  async listarPorUsuario(idUsuario: number): Promise<Restaurante[]> {
    const restaurantes = await this.restauranteRepository.find({
      where: { solicitud: { usuario: { id: idUsuario } } },
      relations: { solicitud: { usuario: true } },
    });

    if (restaurantes.length === 0) {
      // Auto-reparación: Si no tiene restaurante, buscar si tiene solicitud aprobada y crearlo
      const solicitudAprobada = await this.solicitudRepository.findOne({
        where: { usuario: { id: idUsuario }, estado: 'aprobada' },
        relations: { usuario: true },
      });

      if (solicitudAprobada) {
        const nuevoRestaurante = this.restauranteRepository.create({
          solicitud: { id: solicitudAprobada.id },
          nombre: solicitudAprobada.nombreRestaurante,
          tipoComida: solicitudAprobada.tipoComida,
          descripcion: solicitudAprobada.descripcion,
          telefono: solicitudAprobada.celularContacto,
          correo: solicitudAprobada.usuario.correo,
          estado: false,
        });
        const guardado =
          await this.restauranteRepository.save(nuevoRestaurante);
        const conRelaciones = await this.restauranteRepository.findOne({
          where: { id: guardado.id },
          relations: { solicitud: { usuario: true } },
        });
        if (conRelaciones) {
          restaurantes.push(conRelaciones);
        }
      }
    }

    // Adjuntar la ubicación al resultado para el frontend
    const restaurantesConUbicacion = await Promise.all(
      restaurantes.map(async (rest) => {
        const ubicacion = await this.ubicacionRepository.findOne({
          where: { restaurante: { id: rest.id } },
        });
        const horarios = await this.horarioRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        const mesas = await this.mesaRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        const imagenes = await this.imagenRepository.find({
          where: { restaurante: { id: rest.id } },
        });

        // Calcular reseñas
        const resenas = await this.resenaRepository.find({
          where: { restaurante: { id: rest.id } },
        });
        let rating = 0;
        let reviewCount = resenas.length;
        if (reviewCount > 0) {
          const totalScore = resenas.reduce(
            (sum, r) => sum + r.calificacion,
            0,
          );
          rating = parseFloat((totalScore / reviewCount).toFixed(1));
        }

        return {
          ...rest,
          direccion: ubicacion?.direccion,
          latitud: ubicacion?.latitud,
          longitud: ubicacion?.longitud,
          horarios,
          mesas,
          imagenes,
          rating,
          reviewCount,
        };
      }),
    );

    return restaurantesConUbicacion as any;
  }

  async buscarPorId(id: number): Promise<Restaurante> {
    const restaurante = await this.restauranteRepository.findOne({
      where: { id },
      relations: { solicitud: true },
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${id} no encontrado`);
    }
    return restaurante;
  }

  async buscarPorIdPublico(id: number): Promise<Restaurante> {
    const restaurante = await this.buscarPorId(id);
    const ubicacion = await this.ubicacionRepository.findOne({
      where: { restaurante: { id } },
    });
    const horarios = await this.horarioRepository.find({
      where: { restaurante: { id } },
    });
    const mesas = await this.mesaRepository.find({
      where: { restaurante: { id } },
    });
    if (
      !this.perfilPublicable({
        ...restaurante,
        direccion: ubicacion?.direccion,
        latitud: ubicacion?.latitud,
        longitud: ubicacion?.longitud,
        horarios,
        mesas,
      })
    ) {
      throw new NotFoundException(`Restaurante con id ${id} no disponible`);
    }
    return restaurante;
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
      const restaurante = await manager.findOne(Restaurante, { where: { id } });
      if (!restaurante) {
        throw new NotFoundException(`Restaurante con id ${id} no encontrado`);
      }

      const {
        direccion,
        latitud,
        longitud,
        horarios,
        mesasTotal,
        capacidadTotal,
        ...datos
      } = dto;
      Object.assign(restaurante, datos);
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

      const horariosRepo = manager.getRepository(HorarioAtencion);
      if (horarios !== undefined) {
        await horariosRepo.delete({ restaurante: { id } });
        if (horarios.length) {
          await horariosRepo.save(
            horarios.map((horario) =>
              horariosRepo.create({
                restaurante: { id },
                diaSemana: horario.diaSemana,
                horaInicio: horario.horaInicio,
                horaFin: horario.horaFin,
              }),
            ),
          );
        }
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
    });

    await this.activarSiPerfilCompleto(id);
    return this.buscarPorId(id);
  }

  async eliminar(id: number): Promise<void> {
    const restaurante = await this.buscarPorId(id);
    await this.restauranteRepository.delete(restaurante.id);
  }

  async subirPortada(
    id: number,
    file: Express.Multer.File,
  ): Promise<Restaurante> {
    if (!file)
      throw new BadRequestException('Se requiere una imagen de portada');

    const restaurante = await this.buscarPorId(id);

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('El archivo debe ser una imagen');
    }

    const uploadDir = path.join(
      process.cwd(),
      'storage',
      'publico',
      'restaurantes',
      id.toString(),
      'portada',
    );
    await fs.mkdir(uploadDir, { recursive: true });

    const ext = '.webp';
    const filename = `${crypto.randomUUID()}${ext}`;

    await fs.writeFile(
      path.join(uploadDir, filename),
      await sanitizeImage(file),
    );

    const url = `/publico/restaurantes/${id}/portada/${filename}`;
    restaurante.fotoPortada = url;
    const guardado = await this.restauranteRepository.save(restaurante);
    await this.activarSiPerfilCompleto(id);
    return guardado;
  }

  async subirLogo(id: number, file: Express.Multer.File): Promise<Restaurante> {
    if (!file) throw new BadRequestException('Se requiere una imagen de logo');

    const restaurante = await this.buscarPorId(id);

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('El archivo debe ser una imagen');
    }

    const uploadDir = path.join(
      process.cwd(),
      'storage',
      'publico',
      'restaurantes',
      id.toString(),
      'logo',
    );
    await fs.mkdir(uploadDir, { recursive: true });

    const ext = '.webp';
    const filename = `${crypto.randomUUID()}${ext}`;

    await fs.writeFile(
      path.join(uploadDir, filename),
      await sanitizeImage(file),
    );

    restaurante.logo = `/publico/restaurantes/${id}/logo/${filename}`;
    const guardado = await this.restauranteRepository.save(restaurante);
    await this.activarSiPerfilCompleto(id);
    return guardado;
  }

  async subirGaleria(
    id: number,
    files: Express.Multer.File[],
  ): Promise<Restaurante> {
    if (!files || files.length === 0)
      throw new BadRequestException('Se requieren imágenes para la galería');

    const restaurante = await this.buscarPorId(id);
    const uploadDir = path.join(
      process.cwd(),
      'storage',
      'publico',
      'restaurantes',
      id.toString(),
      'galeria',
    );
    await fs.mkdir(uploadDir, { recursive: true });

    const count = await this.imagenRepository.count({
      where: { restaurante: { id } },
    });
    if (count + files.length > 50)
      throw new BadRequestException('La galería admite hasta 50 imágenes');
    const nuevasImagenes: Imagen[] = [];
    for (const file of files) {
      if (!file.mimetype.startsWith('image/'))
        throw new BadRequestException('Los archivos deben ser imágenes');
      const ext = '.webp';
      const filename = `${crypto.randomUUID()}${ext}`;
      await fs.writeFile(
        path.join(uploadDir, filename),
        await sanitizeImage(file),
      );

      nuevasImagenes.push(
        this.imagenRepository.create({
          restaurante: { id: restaurante.id },
          url: `/publico/restaurantes/${id}/galeria/${filename}`,
        }),
      );
    }

    await this.imagenRepository.save(nuevasImagenes);
    return restaurante;
  }
}
