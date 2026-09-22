import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import 'multer';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, IsNull } from 'typeorm';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
import { Solicitud } from './solicitud.entity';
import { CrearSolicitudDto } from './dto/crear-solicitud.dto';
import { ActualizarSolicitudDto } from './dto/actualizar-solicitud.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { DocumentoAdjunto } from '../documento-adjunto/documento-adjunto.entity';
import { Rol } from '../rol/rol.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { InvitacionToken } from '../invitacion-token/invitacion-token.entity';
import { MailService } from '../mail/mail.service';
import { Restaurante } from '../restaurante/restaurante.entity';
import { validateDocument } from '../../core/security/uploads';

@Injectable()
export class SolicitudService {
  private readonly logger = new Logger(SolicitudService.name);

  constructor(
    @InjectRepository(Solicitud)
    private readonly solicitudRepository: Repository<Solicitud>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly dataSource: DataSource,
    private readonly mailService: MailService,
  ) {}

  async crear(
    dto: CrearSolicitudDto,
    files: {
      documentoNit?: Express.Multer.File[];
      documentoCi?: Express.Multer.File[];
    },
  ): Promise<Solicitud> {
    const correoNormalizado = dto.correoUsuario.trim().toLowerCase();
    const tokenVerificacion = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto
      .createHash('sha256')
      .update(tokenVerificacion)
      .digest('hex');
    const nitFile = files?.documentoNit?.[0];
    const ciFile = files?.documentoCi?.[0];

    if (!nitFile || !ciFile) {
      throw new BadRequestException('Se requieren los documentos NIT y CI');
    }

    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
    if (
      !allowedTypes.includes(nitFile.mimetype) ||
      !allowedTypes.includes(ciFile.mimetype)
    ) {
      throw new BadRequestException(
        'Los documentos NIT y CI deben ser PDF, JPG o PNG.',
      );
    }

    await validateDocument(nitFile);
    await validateDocument(ciFile);

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
    let uploadDir: string | undefined;

    try {
      let usuario = await queryRunner.manager.findOne(Usuario, {
        where: { correo: correoNormalizado },
      });

      if (usuario) {
        const pendiente = await queryRunner.manager.findOne(Solicitud, {
          where: { usuario: { id: usuario.id }, estado: 'pendiente' },
        });
        if (pendiente) {
          throw new ConflictException(
            'Ya tienes una solicitud pendiente de revisión.',
          );
        }
      } else {
        usuario = queryRunner.manager.create(Usuario, {
          nombre: dto.nombreUsuario,
          apellido: dto.apellidoUsuario,
          correo: correoNormalizado,
        });
        usuario = await queryRunner.manager.save(usuario);
      }

      let solicitud = queryRunner.manager.create(Solicitud, {
        nombreRestaurante: dto.nombreRestaurante,
        tipoComida: dto.tipoComida,
        nitNegocio: dto.nitNegocio,
        celularContacto: dto.celularContacto,
        descripcion: dto.descripcion,
        horariosAtencion: dto.horariosAtencion,
        motivoRechazo: dto.motivoRechazo,
        usuario,
        estado: 'pendiente',
        correoVerificadoAt: null,
      });
      solicitud = await queryRunner.manager.save(solicitud);

      uploadDir = path.join(
        process.cwd(),
        'storage',
        'privado',
        'solicitudes',
        solicitud.id.toString(),
      );
      await fs.mkdir(uploadDir, { recursive: true });

      const extensionFor = (mimetype: string) => {
        if (mimetype === 'image/jpeg') return '.jpg';
        if (mimetype === 'image/png') return '.png';
        return '.pdf';
      };
      const nitExt = extensionFor(nitFile.mimetype);
      const ciExt = extensionFor(ciFile.mimetype);

      const nitFilename = `nit-${crypto.randomUUID()}${nitExt}`;
      const ciFilename = `ci-${crypto.randomUUID()}${ciExt}`;

      await fs.writeFile(path.join(uploadDir, nitFilename), nitFile.buffer);
      await fs.writeFile(path.join(uploadDir, ciFilename), ciFile.buffer);

      const docNit = queryRunner.manager.create(DocumentoAdjunto, {
        solicitud,
        tipo: 'NIT',
        url: `/privado/solicitudes/${solicitud.id}/${nitFilename}`,
      });
      const docCi = queryRunner.manager.create(DocumentoAdjunto, {
        solicitud,
        tipo: 'CI',
        url: `/privado/solicitudes/${solicitud.id}/${ciFilename}`,
      });

      await queryRunner.manager.save([docNit, docCi]);
      await queryRunner.manager.query(
        `INSERT INTO solicitud_verificacion (id_solicitud, token_hash, expira_at)
         VALUES ($1, $2, NOW() + INTERVAL '24 hours')`,
        [solicitud.id, tokenHash],
      );
      await queryRunner.commitTransaction();

      try {
        await this.mailService.enviarVerificacionSolicitud(
          correoNormalizado,
          tokenVerificacion,
        );
        await this.dataSource.query(
          'UPDATE solicitud_verificacion SET enviado_at = NOW() WHERE id_solicitud = $1 AND token_hash = $2',
          [solicitud.id, tokenHash],
        );
      } catch (error) {
        this.logger.error(
          'No se pudo enviar o registrar el correo de verificación de solicitud.',
          (error as Error)?.message,
        );
      }
      return solicitud;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      // Si la transacción falla después de guardar los archivos, evitar
      // dejar documentos huérfanos en la carpeta privada.
      if (uploadDir) {
        await fs
          .rm(uploadDir, { recursive: true, force: true })
          .catch(() => undefined);
      }
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async verificarCorreo(token: string): Promise<{ mensaje: string }> {
    if (!/^[a-f0-9]{64}$/i.test(token))
      throw new BadRequestException('Enlace de verificación inválido.');
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    await this.dataSource.transaction(async (manager) => {
      const rows: Array<{ id_solicitud: number }> = await manager.query(
        `SELECT id_solicitud FROM solicitud_verificacion
         WHERE token_hash = $1 AND expira_at > NOW() FOR UPDATE`,
        [tokenHash],
      );
      if (!rows.length)
        throw new BadRequestException(
          'El enlace de verificación es inválido o expiró.',
        );
      const updated: Array<{ id_solicitud: number }> = await manager.query(
        `UPDATE solicitud SET correo_verificado_at = NOW()
         WHERE id_solicitud = $1 AND estado = 'pendiente' AND correo_verificado_at IS NULL
         RETURNING id_solicitud`,
        [rows[0].id_solicitud],
      );
      if (!updated.length)
        throw new BadRequestException('La solicitud ya fue procesada.');
      await manager.query(
        'DELETE FROM solicitud_verificacion WHERE id_solicitud = $1',
        [rows[0].id_solicitud],
      );
    });
    return {
      mensaje: 'Correo confirmado. Ahora podemos revisar tu solicitud.',
    };
  }

  async reenviarVerificacion(correo: string): Promise<{ mensaje: string }> {
    const respuesta = {
      mensaje:
        'Si hay una solicitud pendiente, enviaremos un nuevo enlace de confirmación.',
    };
    const normalizado = correo.trim().toLowerCase();
    const solicitud = await this.solicitudRepository.findOne({
      where: {
        usuario: { correo: normalizado },
        estado: 'pendiente',
        correoVerificadoAt: IsNull(),
      },
      relations: { usuario: true },
      order: { id: 'DESC' },
    });
    if (!solicitud) return respuesta;
    const nuevo = await this.dataSource.transaction(async (manager) => {
      const rows: Array<{ enviado_at: Date | null }> = await manager.query(
        `SELECT v.enviado_at FROM solicitud_verificacion v
         JOIN solicitud s ON s.id_solicitud = v.id_solicitud
         WHERE v.id_solicitud = $1 AND s.estado = 'pendiente'
           AND s.correo_verificado_at IS NULL
         FOR UPDATE OF v`,
        [solicitud.id],
      );
      if (
        !rows.length ||
        (rows[0].enviado_at &&
          Date.now() - new Date(rows[0].enviado_at).getTime() < 5 * 60_000)
      ) {
        return null;
      }
      const token = crypto.randomBytes(32).toString('hex');
      const hash = crypto.createHash('sha256').update(token).digest('hex');
      await manager.query(
        `UPDATE solicitud_verificacion SET token_hash = $2,
         expira_at = NOW() + INTERVAL '24 hours', enviado_at = NULL
         WHERE id_solicitud = $1`,
        [solicitud.id, hash],
      );
      return { token, hash };
    });
    if (!nuevo) return respuesta;
    try {
      await this.mailService.enviarVerificacionSolicitud(
        normalizado,
        nuevo.token,
      );
      await this.dataSource.query(
        'UPDATE solicitud_verificacion SET enviado_at = NOW() WHERE id_solicitud = $1 AND token_hash = $2',
        [solicitud.id, nuevo.hash],
      );
    } catch (error) {
      this.logger.error(
        'No se pudo reenviar o registrar la verificación de solicitud.',
        (error as Error)?.message,
      );
    }
    return respuesta;
  }

  listarTodos(estado?: string): Promise<Solicitud[]> {
    const whereCondition = estado
      ? { estado: estado as Solicitud['estado'] }
      : {};
    return this.solicitudRepository.find({
      where: whereCondition,
      relations: { usuario: true, documentosAdjuntos: true },
      order: { fecha: 'DESC' },
    });
  }

  async buscarPorId(id: number): Promise<Solicitud> {
    const solicitud = await this.solicitudRepository.findOne({
      where: { id },
      relations: { usuario: true, documentosAdjuntos: true },
    });
    if (!solicitud) {
      throw new NotFoundException(`Solicitud con id ${id} no encontrada`);
    }
    return solicitud;
  }

  listarPorUsuario(idUsuario: number): Promise<Solicitud[]> {
    return this.solicitudRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { usuario: true },
    });
  }

  async actualizar(
    id: number,
    dto: ActualizarSolicitudDto,
  ): Promise<Solicitud> {
    const solicitud = await this.buscarPorId(id);
    const estadoAnterior = solicitud.estado;
    if (
      dto.estado !== undefined &&
      dto.estado !== estadoAnterior &&
      estadoAnterior !== 'pendiente'
    ) {
      throw new ConflictException(
        'Una solicitud procesada no puede cambiar de estado.',
      );
    }

    if (estadoAnterior === 'pendiente' && dto.estado === 'aprobada') {
      const tokenStr = crypto.randomBytes(32).toString('hex');
      const guardada = await this.dataSource.transaction(async (manager) => {
        const actual = await manager.findOne(Solicitud, {
          where: { id },
          relations: { usuario: true },
          lock: { mode: 'pessimistic_write' },
        });
        if (!actual || actual.estado !== 'pendiente') {
          throw new ConflictException('La solicitud ya fue procesada.');
        }
        if (!actual.correoVerificadoAt) {
          throw new ConflictException(
            'El solicitante todavía no confirmó su correo.',
          );
        }
        const rol = await manager.findOne(Rol, {
          where: { nombre: 'admin_restaurante' },
        });
        if (!rol)
          throw new NotFoundException(
            'Falta configurar el rol admin_restaurante.',
          );
        Object.assign(actual, dto);
        const aprobada = await manager.save(actual);
        const asignacion = await manager.findOne(UsuarioRol, {
          where: { idUsuario: actual.usuario.id, idRol: rol.id },
        });
        if (!asignacion) {
          await manager.save(
            manager.create(UsuarioRol, {
              usuario: { id: actual.usuario.id },
              rol: { id: rol.id },
            }),
          );
        }
        await manager.update(
          InvitacionToken,
          {
            usuario: { id: actual.usuario.id },
            tipo: 'invitacion',
            usado: false,
          },
          { usado: true },
        );
        await manager.save(
          manager.create(InvitacionToken, {
            usuario: { id: actual.usuario.id },
            token: tokenStr,
            tipo: 'invitacion',
            fechaExpiracion: new Date(Date.now() + 48 * 60 * 60 * 1000),
          }),
        );
        await manager.save(
          manager.create(Restaurante, {
            solicitud: { id: actual.id },
            nombre: actual.nombreRestaurante,
            tipoComida: actual.tipoComida,
            descripcion: actual.descripcion,
            telefono: actual.celularContacto,
            correo: actual.usuario.correo,
            estado: false,
          }),
        );
        return aprobada;
      });
      try {
        await this.mailService.enviarInvitacion(
          solicitud.usuario.correo,
          tokenStr,
        );
      } catch (error) {
        this.logger.error(
          'Solicitud aprobada, pero no se pudo enviar la invitación; requiere reenvío manual.',
          (error as Error)?.message,
        );
      }
      return guardada;
    }

    Object.assign(solicitud, dto);
    const guardada = await this.solicitudRepository.save(solicitud);
    if (estadoAnterior === 'pendiente' && dto.estado === 'rechazada') {
      const uploadDir = path.join(
        process.cwd(),
        'storage',
        'privado',
        'solicitudes',
        solicitud.id.toString(),
      );
      try {
        await fs.rm(uploadDir, { recursive: true, force: true });
      } catch (e) {
        this.logger.error(
          'Error al eliminar carpeta de solicitud rechazada',
          (e as Error)?.message,
        );
      }
    }

    return guardada;
  }

  async eliminar(id: number): Promise<void> {
    const solicitud = await this.buscarPorId(id);
    await this.solicitudRepository.delete(solicitud.id);
  }
}
