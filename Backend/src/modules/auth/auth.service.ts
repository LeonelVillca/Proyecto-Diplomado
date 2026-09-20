import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { JwtService } from '@nestjs/jwt';
import { DataSource, In } from 'typeorm';
import { RolPermiso } from '../rol-permiso/rol-permiso.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { UsuariosService } from '../usuarios/usuarios.service';
import { CuentasAuthService } from '../cuentas-auth/cuentas-auth.service';
import { OauthCuentasService } from '../oauth-cuenta/oauth-cuentas.service';
import { GoogleLoginDto } from './dto/google-login.dto';
import { ActualizarUsuarioDto } from '../usuarios/dto/actualizar-usuario.dto';
import { FirebaseAdminService } from './firebase-admin.service';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { InvitacionToken } from '../invitacion-token/invitacion-token.entity';
import { CrearContrasenaDto } from './dto/crear-contrasena.dto';
import { SolicitarRecuperacionDto, RestablecerPasswordDto, VerificarPinDto } from './dto/recuperar-password.dto';
import { MailService } from '../mail/mail.service';
import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomInt, timingSafeEqual } from 'crypto';
import { CuentaAuth } from '../cuentas-auth/cuenta-auth.entity';
import { pinHmacSecret } from '../../core/config/security.config';

function nombreDesdeCorreo(correo: string): string {
  const local = correo.split('@')[0];
  const partes = local.split(/[._\-\d]+/).filter(Boolean);
  const base = partes.length > 0 ? partes : [local];
  return base
    .map(
      (parte) => parte.charAt(0).toUpperCase() + parte.slice(1).toLowerCase(),
    )
    .join(' ');
}

export interface UsuarioPublico {
  id: number;
  nombre: string;
  apellido: string | null;
  correo: string;
  roles?: string[];
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
    private readonly oauthCuentasService: OauthCuentasService,
    private readonly firebaseAdminService: FirebaseAdminService,
    private readonly jwtService: JwtService,
    private readonly dataSource: DataSource,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) { }

  private async emitirTokenAsync(usuario: Usuario, sessionStartedAt = Math.floor(Date.now() / 1000), expectedVersion?: number): Promise<{
    token: string;
    usuario: UsuarioPublico;
  }> {
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta?.estado || usuario.estado !== 'activo' || (expectedVersion !== undefined && cuenta.sessionVersion !== expectedVersion)) {
      throw new UnauthorizedException('La sesión no está autorizada');
    }
    const usuarioRoles = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: usuario.id },
    });

    let permisos: string[] = [];
    if (usuarioRoles.length > 0) {
      const rolIds = usuarioRoles.map((ur) => ur.idRol);
      const rolPermisos = await this.dataSource.getRepository(RolPermiso).find({
        where: { rol: { id: In(rolIds) } },
        relations: { permiso: true },
      });
      permisos = Array.from(new Set(rolPermisos.map((rp) => rp.permiso.codigo)));
    }

    const token = this.jwtService.sign({
      sub: usuario.id,
      correo: usuario.correo,
      permisos,
      sv: cuenta.sessionVersion,
      sessionStartedAt,
    });

    return {
      token,
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        correo: usuario.correo,
      },
    };
  }

  async login(dto: import('./dto/login.dto').LoginDto): Promise<{ token: string; usuario: UsuarioPublico }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    const usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta || !cuenta.passwordHash) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    // VUL-004: Verificar estado ANTES de ejecutar bcrypt (evita timing oracle)
    if (cuenta.estado === false || usuario.estado !== 'activo') {
      throw new UnauthorizedException('La cuenta está suspendida');
    }

    // VUL-003: Verificar límite de intentos fallidos (bloqueo tras 5 intentos)
    const MAX_INTENTOS = 5;
    if (cuenta.intentosFallidos >= MAX_INTENTOS) {
      throw new UnauthorizedException(
        'La cuenta está bloqueada temporalmente por múltiples intentos fallidos. ' +
        'Utiliza la recuperación de contraseña para desbloquearla.',
      );
    }

    const isValid = await bcrypt.compare(dto.password, cuenta.passwordHash);
    if (!isValid) {
      // Incrementar intentos fallidos
      await this.cuentasAuthService.incrementarIntentosFallidos(cuenta.id);
      throw new UnauthorizedException('Credenciales inválidas');
    }

    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return await this.emitirTokenAsync(usuario, Math.floor(Date.now() / 1000), cuenta.sessionVersion);
  }

  /// Inicio de sesión con cuenta de Google.
  ///
  /// El frontend autentica con Google/Firebase y manda el ID Token; aquí se
  /// verifica server-side con `firebase-admin`. Solo si la verificación es
  /// exitosa se crea/actualiza `usuarios`, se vincula `oauth_cuenta`
  /// (proveedor `google`, `proveedor_id` = UID verificado) y se emite el JWT
  /// propio del backend. Si el token es inválido/expirado se responde 401 sin
  /// tocar la base de datos.
  async loginGoogle(
    dto: GoogleLoginDto,
  ): Promise<{ token: string; usuario: UsuarioPublico }> {
    const verificado = await this.firebaseAdminService.verificarIdToken(
      dto.idToken,
    );

    if (!verificado.correo || !verificado.emailVerificado) {
      throw new UnauthorizedException(
        'La cuenta de Google no tiene un correo válido asociado',
      );
    }

    const correoNormalizado = verificado.correo.trim().toLowerCase();

    let nombreFinal = nombreDesdeCorreo(correoNormalizado);
    let apellidoFinal: string | undefined = undefined;

    if (verificado.nombre) {
      const partes = verificado.nombre.trim().split(' ');
      nombreFinal = partes[0];
      if (partes.length > 1) {
        apellidoFinal = partes.slice(1).join(' ');
      }
    }

    let usuario: Usuario | null =
      await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      usuario = await this.usuariosService.crear({
        nombre: nombreFinal,
        apellido: apellidoFinal,
        correo: correoNormalizado,
        foto: verificado.foto ?? undefined,
      });
    } else {
      const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
      if (usuario.estado !== 'activo' || cuenta?.estado === false) {
        throw new UnauthorizedException('La cuenta está suspendida');
      }
      const patch: ActualizarUsuarioDto = {};
      if (verificado.nombre) {
        patch.nombre = nombreFinal;
        patch.apellido = apellidoFinal;
      }
      if (verificado.foto !== null) {
        patch.foto = verificado.foto;
      }
      if (Object.keys(patch).length > 0) {
        usuario = await this.usuariosService.actualizar(usuario.id, patch);
      }
    }

    await this.cuentasAuthService.asegurarCuenta(usuario.id);
    await this.oauthCuentasService.vincularOCrear({
      idUsuario: usuario.id,
      proveedor: 'google',
      proveedorId: verificado.uid,
      emailVerificado: verificado.emailVerificado,
    });
    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return await this.emitirTokenAsync(usuario);
  }

  async perfil(id: number): Promise<UsuarioPublico> {
    const usuario = await this.usuariosService.buscarPorId(id);
    const usuarioRoles = await this.dataSource.getRepository(UsuarioRol).find({
      where: { idUsuario: id },
      relations: { rol: true },
    });
    const roles = usuarioRoles.map((ur) => ur.rol.nombre);

    return {
      id: usuario.id,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      correo: usuario.correo,
      roles,
    };
  }

  renovarSesion(usuario: Usuario & { sessionStartedAt: number; sessionVersion: number }) {
    return this.emitirTokenAsync(usuario, usuario.sessionStartedAt, usuario.sessionVersion);
  }

  async cerrarSesiones(idUsuario: number) {
    await this.cuentasAuthService.revocarSesiones(idUsuario);
    return { mensaje: 'Todas las sesiones fueron cerradas' };
  }

  async crearContrasena(dto: CrearContrasenaDto): Promise<{ mensaje: string }> {
    const invitacion = await this.dataSource.manager.findOne(InvitacionToken, {
      where: { token: dto.token, tipo: 'invitacion' },
      relations: { usuario: true },
    });

    if (!invitacion) {
      throw new BadRequestException('El token es inválido o no existe.');
    }

    if (invitacion.usado) {
      throw new BadRequestException('El token ya ha sido utilizado.');
    }

    if (invitacion.fechaExpiracion < new Date()) {
      throw new BadRequestException('El token ha expirado. Por favor, solicita uno nuevo.');
    }

    await this.cuentasAuthService.asegurarCuenta(invitacion.usuario.id, dto.password);

    invitacion.usado = true;
    await this.dataSource.manager.save(invitacion);

    return { mensaje: 'Contraseña creada exitosamente' };
  }

  private hashPin(idUsuario: number, pin: string): string {
    return createHmac('sha256', pinHmacSecret(this.configService)).update(`recuperacion:${idUsuario}:${pin}`).digest('hex');
  }

  async solicitarRecuperacion(dto: SolicitarRecuperacionDto): Promise<{ mensaje: string }> {
    const usuario = await this.usuariosService.buscarPorCorreo(dto.correo.trim().toLowerCase());
    const respuesta = { mensaje: 'Si el correo existe en el sistema, recibirás un código PIN en los próximos minutos.' };
    if (!usuario || usuario.estado !== 'activo') return respuesta;
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta?.estado) return respuesta;
    const pin = randomInt(100000, 1000000).toString();
    const created = await this.dataSource.transaction(async (manager) => {
      // Bloquear la cuenta serializa solicitudes desde distintas IP/procesos.
      await manager.findOne(CuentaAuth, { where: { id: cuenta.id }, lock: { mode: 'pessimistic_write' } });
      const repo = manager.getRepository(InvitacionToken);
      const last = await repo.findOne({ where: { usuario: { id: usuario.id }, tipo: 'recuperacion' }, order: { id: 'DESC' } });
      if (last && Date.now() - last.fechaCreacion.getTime() < 60_000) return false;
      await repo.update({ usuario: { id: usuario.id }, tipo: 'recuperacion', usado: false }, { usado: true });
      await repo.save(repo.create({
        usuario: { id: usuario.id }, token: this.hashPin(usuario.id, pin), tipo: 'recuperacion',
        fechaExpiracion: new Date(Date.now() + 15 * 60_000),
      }));
      return true;
    });
    if (created) await this.mailService.enviarRecuperacionPassword(usuario.correo, pin);
    return respuesta;
  }

  async verificarPinRecuperacion(dto: VerificarPinDto): Promise<{ valido: boolean }> {
    await this.validarRecuperacion(dto);
    return { valido: true };
  }

  async restablecerPassword(dto: RestablecerPasswordDto): Promise<{ mensaje: string }> {
    await this.validarRecuperacion(dto, dto.nuevaContrasena);
    return { mensaje: 'Contraseña actualizada exitosamente' };
  }

  private async validarRecuperacion(dto: VerificarPinDto, password?: string): Promise<void> {
    const usuario = await this.usuariosService.buscarPorCorreo(dto.correo.trim().toLowerCase());
    if (!usuario || usuario.estado !== 'activo') throw new BadRequestException('El PIN es inválido o ha expirado.');
    const accepted = await this.dataSource.transaction(async (manager) => {
      const cuenta = await manager.findOne(CuentaAuth, {
        where: { usuario: { id: usuario.id } }, lock: { mode: 'pessimistic_write' },
      });
      if (!cuenta?.estado) return false;
      const repo = manager.getRepository(InvitacionToken);
      const record = await repo.findOne({
        where: { usuario: { id: usuario.id }, tipo: 'recuperacion', usado: false },
        order: { id: 'DESC' }, lock: { mode: 'pessimistic_write' },
      });
      if (!record || record.fechaExpiracion <= new Date() || record.intentosVerificacion >= 5) return false;
      const stored = Buffer.from(record.token);
      const supplied = Buffer.from(this.hashPin(usuario.id, dto.pin));
      if (stored.length !== supplied.length || !timingSafeEqual(stored, supplied)) {
        record.intentosVerificacion++;
        if (record.intentosVerificacion >= 5) record.usado = true;
        await repo.save(record);
        return false; // Confirmar el contador antes de devolver el error.
      }
      if (password !== undefined) {
        await manager.update(CuentaAuth, cuenta.id, {
          passwordHash: await bcrypt.hash(password, 12), intentosFallidos: 0,
          sessionVersion: () => 'session_version + 1',
        });
        record.usado = true;
        await repo.save(record);
      }
      return true;
    });
    if (!accepted) throw new BadRequestException('El PIN es inválido o ha expirado.');
  }
}

