import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule, JwtSignOptions } from '@nestjs/jwt';
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
        const expiresIn = configService.get<string>('JWT_EXPIRES_IN') ?? '7d';
        return {
          secret:
            configService.get<string>('JWT_SECRET') ?? 'secreto-diplomado',
          signOptions: { expiresIn: expiresIn as JwtSignOptions['expiresIn'] },
        };
      },
    }),
    UsuariosModule,
    CuentasAuthModule,
    OauthCuentasModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, JwtAuthGuard, FirebaseAdminService],
  exports: [JwtAuthGuard],
})
export class AuthModule {}
