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
}
