import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { Resena } from './resena.entity';
import { CrearResenaDto } from './dto/crear-resena.dto';
import { ActualizarResenaDto } from './dto/actualizar-resena.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { RespuestaResena } from '../respuesta-resena/respuesta-resena.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { Reserva } from '../reservas/reserva.entity';

@Injectable()
export class ResenasService {
  constructor(
    @InjectRepository(Resena)
    private readonly resenasRepo: Repository<Resena>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
    @InjectRepository(Restaurante)
    private readonly restaurantesRepo: Repository<Restaurante>,
    @InjectRepository(RespuestaResena)
    private readonly respuestasRepo: Repository<RespuestaResena>,
    @InjectRepository(UsuarioRol)
    private readonly usuarioRolesRepo: Repository<UsuarioRol>,
    @InjectRepository(Reserva)
    private readonly reservasRepo: Repository<Reserva>,
    private readonly dataSource: DataSource,
  ) {}

  async crear(dto: CrearResenaDto): Promise<Resena> {
    const usuario = await this.usuariosRepo.findOne({
      where: { id: dto.idUsuario },
    });
    if (!usuario) throw new NotFoundException('Usuario no encontrado');

    const restaurante = await this.restaurantesRepo.findOne({
      where: { id: dto.idRestaurante },
    });
    if (!restaurante) throw new NotFoundException('Restaurante no encontrado');

    const reservaFinalizada = await this.reservasRepo.findOne({
      where: {
        usuario: { id: dto.idUsuario },
        mesa: { restaurante: { id: dto.idRestaurante } },
        estado: 'finalizada',
      },
      order: { fecha: 'DESC', hora: 'DESC' },
    });
    if (!reservaFinalizada) {
      throw new BadRequestException(
        'Solo puedes reseñar después de una reserva finalizada.',
      );
    }

    return this.dataSource.transaction(async (manager) => {
      const resenaExistente = await manager.findOne(Resena, {
        where: {
          usuario: { id: dto.idUsuario },
          restaurante: { id: dto.idRestaurante },
        },
      });
      if (resenaExistente) {
        throw new BadRequestException(
          'Ya tienes una reseña para este restaurante.',
        );
      }
      // El UPSERT es atómico: dos peticiones simultáneas no pueden saltarse el plazo.
      const habilitada: Array<{ id_usuario: number }> = await manager.query(
        `INSERT INTO resena_creacion_control (id_usuario, id_restaurante, ultima_creacion)
         VALUES ($1, $2, NOW())
         ON CONFLICT (id_usuario, id_restaurante)
         DO UPDATE SET ultima_creacion = EXCLUDED.ultima_creacion
         WHERE resena_creacion_control.ultima_creacion <= NOW() - INTERVAL '30 days'
         RETURNING id_usuario`,
        [dto.idUsuario, dto.idRestaurante],
      );
      if (!habilitada.length) {
        throw new BadRequestException(
          'Puedes publicar una nueva reseña de este restaurante 30 días después de la anterior.',
        );
      }
      return manager.save(
        manager.create(Resena, {
          ...dto,
          usuario,
          restaurante,
          reserva: reservaFinalizada,
        }),
      );
    });
  }

  listarTodas(): Promise<Resena[]> {
    return this.resenasRepo.find({
      relations: { usuario: true, restaurante: true },
    });
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
    return this.resenasRepo
      .createQueryBuilder('resena')
      .leftJoinAndSelect('resena.usuario', 'usuario')
      .leftJoinAndSelect(
        'respuesta_resena',
        'respuesta',
        'respuesta.id_resena = resena.id_resena',
      )
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
        'respuesta.fechaRespuesta',
      ])
      .getRawMany()
      .then((rows) =>
        rows.map((r) => ({
          id: r.resena_id_resena,
          comentario: r.resena_comentario,
          calificacion: r.resena_calificacion,
          fecha: r.resena_fecha,
          usuario: {
            nombre: r.usuario_nombre,
            apellido: r.usuario_apellido,
          },
          respuesta: r.respuesta_texto
            ? {
                texto: r.respuesta_texto,
                fechaRespuesta: r.respuesta_fecha_respuesta,
              }
            : null,
        })),
      );
  }

  async listarPorUsuario(idUsuario: number): Promise<any[]> {
    return this.resenasRepo
      .createQueryBuilder('resena')
      .leftJoinAndSelect('resena.restaurante', 'restaurante')
      .leftJoinAndSelect(
        'respuesta_resena',
        'respuesta',
        'respuesta.id_resena = resena.id_resena',
      )
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
        'respuesta.fechaRespuesta',
      ])
      .getRawMany()
      .then((rows) =>
        rows.map((r) => ({
          id: r.resena_id_resena,
          comentario: r.resena_comentario,
          calificacion: r.resena_calificacion,
          fecha: r.resena_fecha,
          restaurante: {
            id: r.restaurante_id_restaurante,
            nombre: r.restaurante_nombre,
          },
          respuesta: r.respuesta_texto
            ? {
                texto: r.respuesta_texto,
                fechaRespuesta: r.respuesta_fecha_respuesta,
              }
            : null,
        })),
      );
  }

  async actualizar(
    id: number,
    dto: ActualizarResenaDto,
    actorId?: number,
  ): Promise<Resena> {
    const resena = await this.buscarPorId(id);

    const respuesta = await this.respuestasRepo.findOne({
      where: { resena: { id } },
    });
    if (respuesta && !(await this.esAdminSistema(actorId))) {
      throw new BadRequestException(
        'No puedes editar una reseña que ya recibió respuesta.',
      );
    }

    if (dto.comentario !== undefined) resena.comentario = dto.comentario;
    if (dto.calificacion !== undefined) resena.calificacion = dto.calificacion;

    return this.resenasRepo.save(resena);
  }

  async eliminar(id: number, actorId?: number): Promise<void> {
    const resena = await this.buscarPorId(id);
    const respuesta = await this.respuestasRepo.findOne({
      where: { resena: { id } },
    });
    if (respuesta && !(await this.esAdminSistema(actorId))) {
      throw new BadRequestException(
        'No puedes eliminar una reseña que ya recibió respuesta.',
      );
    }
    await this.resenasRepo.remove(resena);
  }

  private async esAdminSistema(actorId?: number): Promise<boolean> {
    if (!actorId) return false;
    const asignaciones = await this.usuarioRolesRepo.find({
      where: { idUsuario: actorId },
      relations: { rol: true },
    });
    return asignaciones.some(
      (asignacion) => asignacion.rol.nombre === 'admin_sistema',
    );
  }
}
