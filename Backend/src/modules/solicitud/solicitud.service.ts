import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import 'multer';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
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

@Injectable()
export class SolicitudService {
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
    files: { documentoNit?: Express.Multer.File[]; documentoCi?: Express.Multer.File[] },
  ): Promise<Solicitud> {
    const nitFile = files.documentoNit?.[0];
    const ciFile = files.documentoCi?.[0];

    if (!nitFile || !ciFile) {
      throw new BadRequestException('Se requieren los documentos NIT y CI');
    }

    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
    if (!allowedTypes.includes(nitFile.mimetype) || !allowedTypes.includes(ciFile.mimetype)) {
      throw new BadRequestException('Los documentos NIT y CI deben ser PDF, JPG o PNG.');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
    let uploadDir: string | undefined;

    try {
      let usuario = await queryRunner.manager.findOne(Usuario, {
        where: { correo: dto.correoUsuario },
      });

      if (usuario) {
        const pendiente = await queryRunner.manager.findOne(Solicitud, {
          where: { usuario: { id: usuario.id }, estado: 'pendiente' },
        });
        if (pendiente) {
          throw new ConflictException('Ya tienes una solicitud pendiente de revisión.');
        }
      } else {
        usuario = queryRunner.manager.create(Usuario, {
          nombre: dto.nombreUsuario,
          apellido: dto.apellidoUsuario,
          correo: dto.correoUsuario,
        });
        usuario = await queryRunner.manager.save(usuario);
      }

      const { nombreUsuario, apellidoUsuario, correoUsuario, ...datos } = dto;
      let solicitud = queryRunner.manager.create(Solicitud, {
        ...datos,
        usuario,
        estado: 'pendiente',
      });
      solicitud = await queryRunner.manager.save(solicitud);

      uploadDir = path.join(process.cwd(), 'storage', 'privado', 'solicitudes', solicitud.id.toString());
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
      await queryRunner.commitTransaction();

      return solicitud;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      // Si la transacción falla después de guardar los archivos, evitar
      // dejar documentos huérfanos en la carpeta privada.
      if (uploadDir) {
        await fs.rm(uploadDir, { recursive: true, force: true }).catch(() => undefined);
      }
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  listarTodos(estado?: string): Promise<Solicitud[]> {
    const whereCondition = estado ? { estado: estado as Solicitud['estado'] } : {};
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

  async actualizar(id: number, dto: ActualizarSolicitudDto): Promise<Solicitud> {
    const solicitud = await this.buscarPorId(id);
    const estadoAnterior = solicitud.estado;
    
    Object.assign(solicitud, dto);
    const guardada = await this.solicitudRepository.save(solicitud);

    if (estadoAnterior === 'pendiente' && dto.estado === 'aprobada') {
      const rol = await this.dataSource.manager.findOne(Rol, { where: { nombre: 'admin_restaurante' } });
      if (rol) {
        const usuarioRol = this.dataSource.manager.create(UsuarioRol, {
          usuario: { id: solicitud.usuario.id },
          rol: { id: rol.id },
        });
        await this.dataSource.manager.save(usuarioRol).catch(() => {});
      }

      const tokenStr = crypto.randomBytes(32).toString('hex');
      const expiracion = new Date();
      expiracion.setHours(expiracion.getHours() + 48);

      const invitacion = this.dataSource.manager.create(InvitacionToken, {
        usuario: { id: solicitud.usuario.id },
        token: tokenStr,
        tipo: 'invitacion',
        fechaExpiracion: expiracion,
      });
      await this.dataSource.manager.save(invitacion);

      // Enviamos el correo real
      await this.mailService.enviarInvitacion(solicitud.usuario.correo, tokenStr);

      // Crear Restaurante asociado automáticamente
      const nuevoRestaurante = this.dataSource.manager.create(Restaurante, {
        solicitud: { id: solicitud.id },
        nombre: solicitud.nombreRestaurante,
        tipoComida: solicitud.tipoComida,
        descripcion: solicitud.descripcion,
        telefono: solicitud.celularContacto,
        correo: solicitud.usuario.correo,
      });
      await this.dataSource.manager.save(nuevoRestaurante).catch((e) => {
        console.error('Error creando restaurante automático:', e);
      });
    } else if (estadoAnterior === 'pendiente' && dto.estado === 'rechazada') {
      const uploadDir = path.join(process.cwd(), 'storage', 'privado', 'solicitudes', solicitud.id.toString());
      try {
        await fs.rm(uploadDir, { recursive: true, force: true });
      } catch (e) {
        console.error('Error al intentar eliminar la carpeta de la solicitud rechazada:', e);
      }
    }

    return guardada;
  }

  async eliminar(id: number): Promise<void> {
    const solicitud = await this.buscarPorId(id);
    await this.solicitudRepository.delete(solicitud.id);
  }
}
