import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import databaseConfig from './core/config/database.config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsuariosModule } from './modules/usuarios/usuarios.module';
import { RolesModule } from './modules/rol/roles.module';
import { PermisosModule } from './modules/permiso/permisos.module';
import { UsuarioRolModule } from './modules/usuario-rol/usuario-rol.module';
import { CuentasAuthModule } from './modules/cuentas-auth/cuentas-auth.module';
import { OauthCuentasModule } from './modules/oauth-cuenta/oauth-cuentas.module';
import { AuthModule } from './modules/auth/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig],
    }),
    UsuariosModule,
    RolesModule,
    PermisosModule,
    UsuarioRolModule,
    CuentasAuthModule,
    OauthCuentasModule,
    AuthModule,
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        configService.getOrThrow('database'),
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
