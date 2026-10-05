import { Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Usuario } from '../../usuarios/usuario.entity';
import { UsuariosService } from '../../usuarios/usuarios.service';
import { CuentasAuthService } from '../../cuentas-auth/cuentas-auth.service';
import { OauthCuentasService } from '../../oauth-cuenta/oauth-cuentas.service';
import { ActualizarUsuarioDto } from '../../usuarios/dto/actualizar-usuario.dto';
import { LoginDto } from '../dto/login.dto';
import { GoogleLoginDto } from '../dto/google-login.dto';
import { FirebaseAdminService } from '../firebase/firebase-admin.service';
import { UsuarioPublico } from '../contracts/usuario-publico';
import { SesionesService } from './sesiones.service';

// Crea un nombre legible desde el correo si Google no lo envia.
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

@Injectable()
export class AccesoService {
  // Recibe los servicios usados por ambos tipos de ingreso.
  constructor(
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
    private readonly oauthCuentasService: OauthCuentasService,
    private readonly firebaseAdminService: FirebaseAdminService,
    private readonly sesiones: SesionesService,
  ) {}

  // Inicia sesion con correo y contrasena.
  async login(
    dto: LoginDto,
  ): Promise<{ token: string; usuario: UsuarioPublico }> {
    const correoNormalizado = dto.correo.trim().toLowerCase();
    const usuario =
      await this.usuariosService.buscarPorCorreo(correoNormalizado);

    if (!usuario) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (!cuenta || !cuenta.passwordHash) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (cuenta.estado === false || usuario.estado !== 'activo') {
      throw new UnauthorizedException('La cuenta está suspendida');
    }

    const MAX_INTENTOS = 5;
    if (cuenta.intentosFallidos >= MAX_INTENTOS) {
      throw new UnauthorizedException(
        'La cuenta está bloqueada temporalmente por múltiples intentos fallidos. ' +
          'Utiliza la recuperación de contraseña para desbloquearla.',
      );
    }

    const isValid = await bcrypt.compare(dto.password, cuenta.passwordHash);
    if (!isValid) {
      await this.cuentasAuthService.incrementarIntentosFallidos(cuenta.id);
      throw new UnauthorizedException('Credenciales inválidas');
    }

    await this.cuentasAuthService.registrarUltimoIngreso(usuario.id);
    return await this.sesiones.emitirTokenAsync(
      usuario,
      Math.floor(Date.now() / 1000),
      cuenta.sessionVersion,
    );
  }

  // Inicia sesion con una identidad verificada por Google.
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
    return await this.sesiones.emitirTokenAsync(usuario);
  }
}
