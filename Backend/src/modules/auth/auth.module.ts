import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { jwtSecret } from '../../core/config/security.config';
import { PassportModule } from '@nestjs/passport';
import { UsuariosModule } from '../usuarios/usuarios.module';
import { CuentasAuthModule } from '../cuentas-auth/cuentas-auth.module';
import { OauthCuentasModule } from '../oauth-cuenta/oauth-cuentas.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { FirebaseAdminService } from './firebase-admin.service';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        return {
          secret: jwtSecret(configService),
          signOptions: { expiresIn: '1h', algorithm: 'HS256', issuer: 'mesa-chapaca', audience: 'mesa-chapaca-app' },
          verifyOptions: { algorithms: ['HS256'], issuer: 'mesa-chapaca', audience: 'mesa-chapaca-app' },
        };
      },
    }),
    UsuariosModule,
    CuentasAuthModule,
    OauthCuentasModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, JwtAuthGuard, FirebaseAdminService],
  exports: [JwtAuthGuard, JwtStrategy],
})
export class AuthModule {}
