import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Usuario } from '../usuarios/usuario.entity';
import { UsuariosService } from '../usuarios/usuarios.service';
import { CuentasAuthService } from '../cuentas-auth/cuentas-auth.service';
import { OauthCuentasService } from '../oauth-cuenta/oauth-cuentas.service';
import { LoginDto } from './dto/login.dto';
import { RegistroDto } from './dto/registro.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { ActualizarUsuarioDto } from '../usuarios/dto/actualizar-usuario.dto';

function nombreDesdeCorreo(correo: string): string {
  const local = correo.split('@')[0];
  const partes = local.split(/[._\-\d]+/).filter(Boolean);
  const base = partes.length > 0 ? partes : [local];
  return base
    .map((parte) => parte.charAt(0).toUpperCase() + parte.slice(1).toLowerCase())
    .join(' ');
}

export interface UsuarioPublico {
  id: number;
  nombre: string;
  apellido: string | null;
  correo: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
    private readonly oauthCuentasService: OauthCuentasService,
    private readonly jwtService: JwtService,
  ) {}

  private async buscarOCrearUsuario(
    correo: string,
    nombre?: string,
    apellido?: string,
  ): Promise<Usuario> {
    const correoNormalizado = correo.trim().toLowerCase();
    let usuario = await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      usuario = await this.usuariosService.crear({
        nombre: nombre ?? nombreDesdeCorreo(correoNormalizado),
        apellido,
        correo: correoNormalizado,
      });
    }

    return usuario;
  }

  private emitirToken(usuario: Usuario): { token: string; usuario: UsuarioPublico } {
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

  async login(dto: LoginDto): Promise<{ token: string; usuario: UsuarioPublico }> {
    const usuario = await this.buscarOCrearUsuario(dto.correo, undefined, undefined);
    await this.cuentasAuthService.asegurarCuenta(usuario.id, dto.password);
    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return this.emitirToken(usuario);
  }

  async registro(dto: RegistroDto): Promise<{ token: string; usuario: UsuarioPublico }> {
    const usuario = await this.buscarOCrearUsuario(
      dto.correo,
      dto.nombre,
      dto.apellido,
    );
    await this.cuentasAuthService.asegurarCuenta(usuario.id, dto.password);
    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return this.emitirToken(usuario);
  }

  /// Inicio de sesión con cuenta de Google (desde Firebase en el frontend).
  ///
  /// Busca o crea el usuario por correo, actualiza sus datos públicos con
  /// lo que trae Google, vincula `oauth_cuenta` (proveedor `google`) y
  /// devuelve un JWT, igual que el login local. Así el login con Google
  /// también queda registrado en la base de datos.
  async loginGoogle(
    dto: GoogleLoginDto,
  ): Promise<{ token: string; usuario: UsuarioPublico }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    let usuario: Usuario | null =
      await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      usuario = await this.usuariosService.crear({
        nombre: dto.nombre,
        apellido: dto.apellido,
        correo: correoNormalizado,
        foto: dto.foto,
      });
    } else {
      const patch: ActualizarUsuarioDto = {};
      if (dto.nombre) {
        patch.nombre = dto.nombre;
      }
      if (dto.apellido !== undefined) {
        patch.apellido = dto.apellido;
      }
      if (dto.foto !== undefined) {
        patch.foto = dto.foto;
      }
      if (Object.keys(patch).length > 0) {
        usuario = await this.usuariosService.actualizar(usuario.id, patch);
      }
    }

    await this.cuentasAuthService.asegurarCuenta(usuario.id);
    await this.oauthCuentasService.vincularOCrear({
      idUsuario: usuario.id,
      proveedor: 'google',
      proveedorId: dto.proveedorId,
      emailVerificado: dto.emailVerificado ?? true,
    });
    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return this.emitirToken(usuario);
  }

  async perfil(id: number): Promise<UsuarioPublico> {
    const usuario = await this.usuariosService.buscarPorId(id);
    return {
      id: usuario.id,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      correo: usuario.correo,
    };
  }
}