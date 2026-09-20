import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Usuario } from '../usuarios/usuario.entity';
import { UsuariosService } from '../usuarios/usuarios.service';
import { CuentasAuthService } from '../cuentas-auth/cuentas-auth.service';
import { jwtSecret } from '../../core/config/security.config';

export interface JwtPayload {
  sub: number;
  correo: string;
  sv: number;
  sessionStartedAt: number;
  exp: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private readonly usuariosService: UsuariosService,
    private readonly cuentasAuthService: CuentasAuthService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret(configService),
      algorithms: ['HS256'],
      issuer: 'mesa-chapaca',
      audience: 'mesa-chapaca-app',
    });
  }

  async validate(payload: JwtPayload): Promise<Usuario & { sessionStartedAt: number; sessionVersion: number }> {
    const now = Math.floor(Date.now() / 1000);
    if (!Number.isSafeInteger(payload.sub) || payload.sub <= 0 || !Number.isInteger(payload.sv)
      || !Number.isInteger(payload.sessionStartedAt) || payload.sessionStartedAt > now
      || now - payload.sessionStartedAt >= 7 * 24 * 3600 || !payload.exp || payload.exp <= now) {
      throw new UnauthorizedException();
    }
    const cuenta = await this.cuentasAuthService.buscarPorUsuario(payload.sub);
    if (!cuenta || !cuenta.estado || cuenta.usuario.estado !== 'activo' || cuenta.sessionVersion !== payload.sv) {
      throw new UnauthorizedException('La sesión ha expirado o fue revocada');
    }
    return Object.assign(cuenta.usuario, { sessionStartedAt: payload.sessionStartedAt, sessionVersion: payload.sv });
  }
}
