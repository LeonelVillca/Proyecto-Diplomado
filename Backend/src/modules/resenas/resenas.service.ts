import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Resena } from './resena.entity';
import { CrearResenaDto } from './dto/crear-resena.dto';
import { ActualizarResenaDto } from './dto/actualizar-resena.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class ResenasService {
  constructor(
    @InjectRepository(Resena)
    private readonly resenasRepo: Repository<Resena>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
    @InjectRepository(Restaurante)
    private readonly restaurantesRepo: Repository<Restaurante>,
  ) {}

  async crear(dto: CrearResenaDto): Promise<Resena> {
    const usuario = await this.usuariosRepo.findOne({ where: { id: dto.idUsuario } });
    if (!usuario) throw new NotFoundException('Usuario no encontrado');

    const restaurante = await this.restaurantesRepo.findOne({ where: { id: dto.idRestaurante } });
    if (!restaurante) throw new NotFoundException('Restaurante no encontrado');

    const resenaExistente = await this.resenasRepo.findOne({
      where: {
        usuario: { id: dto.idUsuario },
        restaurante: { id: dto.idRestaurante }
      }
    });

    if (resenaExistente) {
      throw new BadRequestException('El usuario ya ha creado una reseña para este restaurante');
    }

    const resena = this.resenasRepo.create({
      ...dto,
      usuario,
      restaurante,
    });

    return this.resenasRepo.save(resena);
  }

  listarTodas(): Promise<Resena[]> {
    return this.resenasRepo.find({ relations: { usuario: true, restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Resena> {
    const resena = await this.resenasRepo.findOne({
      where: { id },
      relations: { usuario: true, restaurante: true },
    });
    if (!resena) throw new NotFoundException(`Resena #${id} no encontrada`);
    return resena;
  }
  
  async listarPorRestaurante(idRestaurante: number): Promise<any[]> {
    return this.resenasRepo.createQueryBuilder('resena')
      .leftJoinAndSelect('resena.usuario', 'usuario')
      .leftJoinAndSelect('respuesta_resena', 'respuesta', 'respuesta.id_resena = resena.id_resena')
      .where('resena.id_restaurante = :idRestaurante', { idRestaurante })
      .orderBy('resena.fecha', 'DESC')
      .select([
        'resena.id',
        'resena.comentario',
        'resena.calificacion',
        'resena.fecha',
        'usuario.nombre',
        'usuario.apellido',
        'respuesta.texto',
        'respuesta.fechaRespuesta'
      ])
      .getRawMany()
      .then(rows => rows.map(r => ({
        id: r.resena_id_resena,
        comentario: r.resena_comentario,
        calificacion: r.resena_calificacion,
        fecha: r.resena_fecha,
        usuario: {
          nombre: r.usuario_nombre,
          apellido: r.usuario_apellido,
        },
        respuesta: r.respuesta_texto ? {
          texto: r.respuesta_texto,
          fechaRespuesta: r.respuesta_fecha_respuesta
        } : null
      })));
  }

  async listarPorUsuario(idUsuario: number): Promise<any[]> {
    return this.resenasRepo.createQueryBuilder('resena')
      .leftJoinAndSelect('resena.restaurante', 'restaurante')
      .leftJoinAndSelect('respuesta_resena', 'respuesta', 'respuesta.id_resena = resena.id_resena')
      .where('resena.id_usuario = :idUsuario', { idUsuario })
      .orderBy('resena.fecha', 'DESC')
      .select([
        'resena.id',
        'resena.comentario',
        'resena.calificacion',
        'resena.fecha',
        'restaurante.id',
        'restaurante.nombre',
        'respuesta.texto',
        'respuesta.fechaRespuesta'
      ])
      .getRawMany()
      .then(rows => rows.map(r => ({
        id: r.resena_id_resena,
        comentario: r.resena_comentario,
        calificacion: r.resena_calificacion,
        fecha: r.resena_fecha,
        restaurante: {
          id: r.restaurante_id_restaurante,
          nombre: r.restaurante_nombre,
        },
        respuesta: r.respuesta_texto ? {
          texto: r.respuesta_texto,
          fechaRespuesta: r.respuesta_fecha_respuesta
        } : null
      })));
  }

  async actualizar(id: number, dto: ActualizarResenaDto): Promise<Resena> {
    const resena = await this.buscarPorId(id);

    if (dto.comentario !== undefined) resena.comentario = dto.comentario;
    if (dto.calificacion !== undefined) resena.calificacion = dto.calificacion;

    return this.resenasRepo.save(resena);
  }

  async eliminar(id: number): Promise<void> {
    const resena = await this.buscarPorId(id);
    await this.resenasRepo.remove(resena);
  }
}
