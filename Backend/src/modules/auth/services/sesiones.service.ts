import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DataSource, In } from 'typeorm';
import { RolPermiso } from '../../rol-permiso/rol-permiso.entity';
import { Usuario } from '../../usuarios/usuario.entity';
import { UsuariosService } from '../../usuarios/usuarios.service';
import { CuentasAuthService } from '../../cuentas-auth/cuentas-auth.service';
import { UsuarioRol } from '../../usuario-rol/usuario-rol.entity';
import { UsuarioPublico } from '../contracts/usuario-publico';

@Injectable()
export class SesionesService {
  // Recibe los servicios para emitir y revocar sesiones.
  constructor(
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
    private readonly jwtService: JwtService,
    private readonly dataSource: DataSource,
  ) {}

  // Emite un token con permisos y version de sesion.
  async emitirTokenAsync(
    usuario: Usuario,
    sessionStartedAt = Math.floor(Date.now() / 1000),
    expectedVersion?: number,
  ): Promise<{
    token: string;
    usuario: UsuarioPublico;
  }> {
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(usuario.id);
    if (
      !cuenta?.estado ||
      usuario.estado !== 'activo' ||
      (expectedVersion !== undefined &&
        cuenta.sessionVersion !== expectedVersion)
    ) {
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
      permisos = Array.from(
        new Set(rolPermisos.map((rp) => rp.permiso.codigo)),
      );
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

  // Devuelve los datos publicos del usuario y sus roles.
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

  // Renueva el token sin reiniciar la edad de la sesion.
  renovarSesion(
    usuario: Usuario & { sessionStartedAt: number; sessionVersion: number },
  ) {
    return this.emitirTokenAsync(
      usuario,
      usuario.sessionStartedAt,
      usuario.sessionVersion,
    );
  }

  // Revoca todas las sesiones del usuario.
  async cerrarSesiones(idUsuario: number) {
    await this.cuentasAuthService.revocarSesiones(idUsuario);
    return { mensaje: 'Todas las sesiones fueron cerradas' };
  }
}
