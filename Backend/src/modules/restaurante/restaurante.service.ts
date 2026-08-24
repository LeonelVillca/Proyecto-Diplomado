import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
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
  ) {}

  async crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    if (dto.idSolicitud !== undefined) {
      const solicitud = await this.solicitudRepository.findOneBy({
        id: dto.idSolicitud,
      });
      if (!solicitud) {
        throw new NotFoundException(`Solicitud con id ${dto.idSolicitud} no encontrada`);
      }
    }

    const { idSolicitud, ...datos } = dto;
    const restaurante = this.restauranteRepository.create({
      ...datos,
      solicitud: idSolicitud ? { id: idSolicitud } : null,
    });
    return this.restauranteRepository.save(restaurante);
  }

  listarTodos(): Promise<Restaurante[]> {
    return this.restauranteRepository.find({ relations: { solicitud: true } });
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
        });
        const guardado = await this.restauranteRepository.save(nuevoRestaurante);
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
        const horarios = await this.horarioRepository.find({ where: { restaurante: { id: rest.id } } });
        const mesas = await this.mesaRepository.find({ where: { restaurante: { id: rest.id } } });
        const imagenes = await this.imagenRepository.find({ where: { restaurante: { id: rest.id } } });
        
        return {
          ...rest,
          direccion: ubicacion?.direccion,
          latitud: ubicacion?.latitud,
          longitud: ubicacion?.longitud,
          horarios,
          mesas,
          imagenes,
        };
      })
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

  async actualizar(id: number, dto: ActualizarRestauranteDto): Promise<Restaurante> {
    const restaurante = await this.buscarPorId(id);

    if (dto.idSolicitud !== undefined) {
      const solicitud = await this.solicitudRepository.findOneBy({
        id: dto.idSolicitud,
      });
      if (!solicitud) {
        throw new NotFoundException(`Solicitud con id ${dto.idSolicitud} no encontrada`);
      }
      restaurante.solicitud = solicitud;
    }

    const { idSolicitud: _ignorado, direccion, latitud, longitud, horarios, mesasTotal, capacidadTotal, ...datos } = dto;
    Object.assign(restaurante, datos);
    await this.restauranteRepository.save(restaurante);

    if (direccion !== undefined || latitud !== undefined || longitud !== undefined) {
      let ubicacion = await this.ubicacionRepository.findOne({
        where: { restaurante: { id: restaurante.id } },
      });
      if (!ubicacion) {
        ubicacion = this.ubicacionRepository.create({ restaurante: { id: restaurante.id } });
      }
      if (direccion !== undefined) ubicacion.direccion = direccion;
      if (latitud !== undefined) ubicacion.latitud = latitud;
      if (longitud !== undefined) ubicacion.longitud = longitud;
      await this.ubicacionRepository.save(ubicacion);
    }

    if (horarios !== undefined) {
      await this.horarioRepository.delete({ restaurante: { id: restaurante.id } });
      if (horarios.length > 0) {
        const nuevosHorarios = horarios.map(h => this.horarioRepository.create({
          restaurante: { id: restaurante.id },
          diaSemana: h.diaSemana,
          horaInicio: h.horaInicio,
          horaFin: h.horaFin
        }));
        await this.horarioRepository.save(nuevosHorarios);
      }
    }

    if (mesasTotal !== undefined && capacidadTotal !== undefined) {
      const mesasActuales = await this.mesaRepository.count({ where: { restaurante: { id: restaurante.id } } });
      if (mesasActuales === 0 && mesasTotal > 0) {
        const capacidadPorMesa = Math.floor(capacidadTotal / mesasTotal);
        const mesasGeneradas = Array.from({ length: mesasTotal }).map((_, i) => this.mesaRepository.create({
          restaurante: { id: restaurante.id },
          numeroMesa: `Mesa ${i + 1}`,
          capacidad: capacidadPorMesa,
          estado: 'libre'
        }));
        await this.mesaRepository.save(mesasGeneradas);
      }
    }

    return restaurante;
  }

  async eliminar(id: number): Promise<void> {
    const restaurante = await this.buscarPorId(id);
    await this.restauranteRepository.delete(restaurante.id);
  }

  async subirPortada(id: number, file: Express.Multer.File): Promise<Restaurante> {
    if (!file) throw new BadRequestException('Se requiere una imagen de portada');
    
    const restaurante = await this.buscarPorId(id);
    
    if (!file.mimetype.startsWith('image/')) {
       throw new BadRequestException('El archivo debe ser una imagen');
    }

    const uploadDir = path.join(process.cwd(), 'storage', 'publico', 'restaurantes', id.toString(), 'portada');
    await fs.mkdir(uploadDir, { recursive: true });
    
    const ext = path.extname(file.originalname) || '.webp';
    const filename = `${crypto.randomUUID()}${ext}`;
    
    await fs.writeFile(path.join(uploadDir, filename), file.buffer);
    
    const url = `/publico/restaurantes/${id}/portada/${filename}`;
    restaurante.fotoPortada = url;
    
    return this.restauranteRepository.save(restaurante);
  }

  async subirLogo(id: number, file: Express.Multer.File): Promise<Restaurante> {
    if (!file) throw new BadRequestException('Se requiere una imagen de logo');
    
    const restaurante = await this.buscarPorId(id);
    
    if (!file.mimetype.startsWith('image/')) {
       throw new BadRequestException('El archivo debe ser una imagen');
    }

    const uploadDir = path.join(process.cwd(), 'storage', 'publico', 'restaurantes', id.toString(), 'logo');
    await fs.mkdir(uploadDir, { recursive: true });
    
    const ext = path.extname(file.originalname) || '.webp';
    const filename = `${crypto.randomUUID()}${ext}`;
    
    await fs.writeFile(path.join(uploadDir, filename), file.buffer);
    
    restaurante.logo = `/publico/restaurantes/${id}/logo/${filename}`;
    
    return this.restauranteRepository.save(restaurante);
  }

  async subirGaleria(id: number, files: Express.Multer.File[]): Promise<Restaurante> {
    if (!files || files.length === 0) throw new BadRequestException('Se requieren imágenes para la galería');
    
    const restaurante = await this.buscarPorId(id);
    const uploadDir = path.join(process.cwd(), 'storage', 'publico', 'restaurantes', id.toString(), 'galeria');
    await fs.mkdir(uploadDir, { recursive: true });
    
    const nuevasImagenes = await Promise.all(
      files.map(async (file) => {
        if (!file.mimetype.startsWith('image/')) throw new BadRequestException('Los archivos deben ser imágenes');
        const ext = path.extname(file.originalname) || '.webp';
        const filename = `${crypto.randomUUID()}${ext}`;
        await fs.writeFile(path.join(uploadDir, filename), file.buffer);
        
        return this.imagenRepository.create({
          restaurante: { id: restaurante.id },
          url: `/publico/restaurantes/${id}/galeria/${filename}`
        });
      })
    );
    
    await this.imagenRepository.save(nuevasImagenes);
    return restaurante;
  }
}