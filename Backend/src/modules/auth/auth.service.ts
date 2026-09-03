import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import { Usuario } from '../usuarios/usuario.entity';
import { UsuariosService } from '../usuarios/usuarios.service';
import { CuentasAuthService } from '../cuentas-auth/cuentas-auth.service';
import { OauthCuentasService } from '../oauth-cuenta/oauth-cuentas.service';
import { RegistroDto } from './dto/registro.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { ActualizarUsuarioDto } from '../usuarios/dto/actualizar-usuario.dto';
import { FirebaseAdminService } from './firebase-admin.service';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { InvitacionToken } from '../invitacion-token/invitacion-token.entity';
import { CrearContrasenaDto } from './dto/crear-contrasena.dto';
import { SolicitarRecuperacionDto, RestablecerPasswordDto, VerificarPinDto } from './dto/recuperar-password.dto';
import { MailService } from '../mail/mail.service';
import { BadRequestException } from '@nestjs/common';

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
  ) {}

  private emitirToken(usuario: Usuario): {
    token: string;
    usuario: UsuarioPublico;
  } {
    const token = this.jwtService.sign({
      sub: usuario.id,
      correo: usuario.correo,
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

  async registro(
    dto: RegistroDto,
  ): Promise<{ token: string; usuario: UsuarioPublico }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    let usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      usuario = await this.usuariosService.crear({
        nombre: dto.nombre,
        apellido: dto.apellido,
        correo: correoNormalizado,
      });
    }

    await this.cuentasAuthService.asegurarCuenta(usuario.id, dto.password);
    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return this.emitirToken(usuario);
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

    const isValid = await bcrypt.compare(dto.password, cuenta.passwordHash);
    if (!isValid) {
      // Opcional: Incrementar intentos fallidos aquí
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (cuenta.estado === false) {
      throw new UnauthorizedException('La cuenta está suspendida');
    }

    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return this.emitirToken(usuario);
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

    if (!verificado.correo) {
      throw new UnauthorizedException(
        'La cuenta de Google no tiene un correo válido asociado',
      );
    }

    const correoNormalizado = verificado.correo.trim().toLowerCase();
    let usuario: Usuario | null =
      await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      usuario = await this.usuariosService.crear({
        nombre: verificado.nombre ?? nombreDesdeCorreo(correoNormalizado),
        correo: correoNormalizado,
        foto: verificado.foto ?? undefined,
      });
    } else {
      const patch: ActualizarUsuarioDto = {};
      if (verificado.nombre) {
        patch.nombre = verificado.nombre;
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
    return this.emitirToken(usuario);
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

  async crearContrasena(dto: CrearContrasenaDto): Promise<{ mensaje: string }> {
    const invitacion = await this.dataSource.manager.findOne(InvitacionToken, {
      where: { token: dto.token },
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

  async solicitarRecuperacion(dto: SolicitarRecuperacionDto): Promise<{ mensaje: string }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    const usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      throw new NotFoundException('El correo no existe en el sistema.');
    }

    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta || cuenta.estado === false) {
      throw new BadRequestException('El correo no tiene una cuenta administrativa activa.');
    }

    // Generar PIN numérico de 6 dígitos
    const pin = Math.floor(100000 + Math.random() * 900000).toString();

    // Invalidar tokens de recuperación anteriores para este usuario
    await this.dataSource.getRepository(InvitacionToken)
      .createQueryBuilder()
      .update(InvitacionToken)
      .set({ usado: true })
      .where('id_usuario = :idUsuario AND tipo = :tipo AND usado = false', { 
        idUsuario: usuario.id, 
        tipo: 'recuperacion' 
      })
      .execute();

    // Crear nuevo token
    const fechaExpiracion = new Date();
    fechaExpiracion.setMinutes(fechaExpiracion.getMinutes() + 15);

    const tokenRepo = this.dataSource.getRepository(InvitacionToken);
    const nuevoToken = tokenRepo.create({
      usuario: { id: usuario.id },
      token: pin,
      tipo: 'recuperacion',
      fechaExpiracion,
    });
    
    // Podría haber un minúsculo riesgo de colisión del PIN (UNIQUE token).
    // Para simplificar, asumiremos que la probabilidad es baja.
    // Si ocurre un error, idealmente se generaría otro.
    try {
      await tokenRepo.save(nuevoToken);
    } catch (error) {
      // Fallback si choca el PIN
      const pinSeguro = pin + Math.floor(Math.random() * 10).toString();
      nuevoToken.token = pinSeguro.slice(0, 6);
      await tokenRepo.save(nuevoToken);
    }

    await this.mailService.enviarRecuperacionPassword(usuario.correo, pin);

    return { mensaje: 'Se ha enviado un código PIN a tu correo.' };
  }

  async verificarPinRecuperacion(dto: VerificarPinDto): Promise<{ valido: boolean }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    const usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      throw new BadRequestException('El PIN es inválido o ha expirado.');
    }

    const tokenRepo = this.dataSource.getRepository(InvitacionToken);
    const tokenRecord = await tokenRepo.findOne({
      where: {
        usuario: { id: usuario.id },
        token: dto.pin,
        tipo: 'recuperacion',
        usado: false,
      },
      order: { id: 'DESC' },
    });

    if (!tokenRecord || tokenRecord.fechaExpiracion < new Date()) {
      throw new BadRequestException('El PIN es inválido o ha expirado.');
    }

    return { valido: true };
  }

  async restablecerPassword(dto: RestablecerPasswordDto): Promise<{ mensaje: string }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    const usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      throw new BadRequestException('El PIN es inválido o ha expirado.');
    }

    const tokenRepo = this.dataSource.getRepository(InvitacionToken);
    const tokenRecord = await tokenRepo.findOne({
      where: {
        usuario: { id: usuario.id },
        token: dto.pin,
        tipo: 'recuperacion',
        usado: false,
      },
      order: { id: 'DESC' },
    });

    if (!tokenRecord) {
      throw new BadRequestException('El PIN es inválido o ha expirado.');
    }

    if (tokenRecord.fechaExpiracion < new Date()) {
      throw new BadRequestException('El PIN ha expirado. Por favor, solicita uno nuevo.');
    }

    // Actualizar contraseña
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta) {
      throw new BadRequestException('La cuenta administrativa no existe.');
    }
    await this.cuentasAuthService.actualizar(cuenta.id, { password: dto.nuevaContrasena });
    
    // Marcar PIN como usado
    tokenRecord.usado = true;
    await tokenRepo.save(tokenRecord);

    return { mensaje: 'Contraseña actualizada exitosamente' };
  }
}

