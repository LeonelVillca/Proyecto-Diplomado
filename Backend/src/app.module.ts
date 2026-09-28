import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AuditInterceptor } from './core/security/audit.interceptor';

import databaseConfig from './core/config/database.config';
import {
  AUTH_RATE_LIMITS,
  validateSecurityEnvironment,
} from './core/config/security.config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsuariosModule } from './modules/usuarios/usuarios.module';
import { RolesModule } from './modules/rol/roles.module';
import { PermisosModule } from './modules/permiso/permisos.module';
import { UsuarioRolModule } from './modules/usuario-rol/usuario-rol.module';
import { RolPermisoModule } from './modules/rol-permiso/rol-permiso.module';
import { SolicitudModule } from './modules/solicitud/solicitud.module';
import { DocumentoAdjuntoModule } from './modules/documento-adjunto/documento-adjunto.module';
import { RestauranteModule } from './modules/restaurante/restaurante.module';
import { UbicacionModule } from './modules/ubicacion/ubicacion.module';
import { HorarioAtencionModule } from './modules/horario-atencion/horario-atencion.module';
import { MesaModule } from './modules/mesa/mesa.module';
import { MenuModule } from './modules/menu/menu.module';
import { PlatoModule } from './modules/plato/plato.module';
import { ImagenModule } from './modules/imagen/imagen.module';
import { CategoriaSoporteModule } from './modules/categoria-soporte/categoria-soporte.module';
import { SoporteModule } from './modules/soporte/soporte.module';
import { ReservasModule } from './modules/reservas/reservas.module';
import { ResenasModule } from './modules/resenas/resenas.module';
import { RespuestaResenaModule } from './modules/respuesta-resena/respuesta-resena.module';
import { CuentasAuthModule } from './modules/cuentas-auth/cuentas-auth.module';
import { OauthCuentasModule } from './modules/oauth-cuenta/oauth-cuentas.module';
import { AuthModule } from './modules/auth/auth.module';
import { InvitacionTokenModule } from './modules/invitacion-token/invitacion-token.module';
import { MailModule } from './modules/mail/mail.module';
import { NotificacionesModule } from './modules/notificaciones/notificaciones.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateSecurityEnvironment,
      load: [databaseConfig],
    }),
    // VUL-019: Rate limiting global — 100 peticiones por minuto por IP
    ThrottlerModule.forRoot(AUTH_RATE_LIMITS),
    UsuariosModule,
    RolesModule,
    PermisosModule,
    UsuarioRolModule,
    RolPermisoModule,
    SolicitudModule,
    DocumentoAdjuntoModule,
    RestauranteModule,
    UbicacionModule,
    HorarioAtencionModule,
    MesaModule,
    MenuModule,
    PlatoModule,
    ImagenModule,
    CategoriaSoporteModule,
    SoporteModule,
    ReservasModule,
    NotificacionesModule,
    ResenasModule,
    RespuestaResenaModule,
    CuentasAuthModule,
    OauthCuentasModule,
    AuthModule,
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        configService.getOrThrow('database'),
    }),
    InvitacionTokenModule,
    MailModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
    // Aplicar ThrottlerGuard globalmente a todos los endpoints
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
