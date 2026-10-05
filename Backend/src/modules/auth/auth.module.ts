import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { jwtSecret } from '../../core/config/security.config';
import { PassportModule } from '@nestjs/passport';
import { UsuariosModule } from '../usuarios/usuarios.module';
import { CuentasAuthModule } from '../cuentas-auth/cuentas-auth.module';
import { OauthCuentasModule } from '../oauth-cuenta/oauth-cuentas.module';
import { AccesoService } from './services/acceso.service';
import { SesionesService } from './services/sesiones.service';
import { ContrasenasService } from './services/contrasenas.service';
import { RecuperacionService } from './services/recuperacion.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './security/jwt.strategy';
import { JwtAuthGuard } from './security/jwt-auth.guard';
import { FirebaseAdminService } from './firebase/firebase-admin.service';
import { FirebaseAppService } from './firebase/firebase-app.service';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        return {
          secret: jwtSecret(configService),
          signOptions: {
            expiresIn: '1h',
            algorithm: 'HS256',
            issuer: 'mesa-chapaca',
            audience: 'mesa-chapaca-app',
          },
          verifyOptions: {
            algorithms: ['HS256'],
            issuer: 'mesa-chapaca',
            audience: 'mesa-chapaca-app',
          },
        };
      },
    }),
    UsuariosModule,
    CuentasAuthModule,
    OauthCuentasModule,
  ],
  controllers: [AuthController],
  providers: [
    AccesoService,
    SesionesService,
    ContrasenasService,
    RecuperacionService,
    JwtStrategy,
    JwtAuthGuard,
    FirebaseAppService,
    FirebaseAdminService,
  ],
  exports: [JwtAuthGuard, JwtStrategy, FirebaseAppService],
})
export class AuthModule {}
