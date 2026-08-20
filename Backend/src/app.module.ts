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
import { ReportesModule } from './modules/reportes/reportes.module';
import { NotificacionModule } from './modules/notificacion/notificacion.module';
import { VisitaModule } from './modules/visita/visita.module';
import { ReservasModule } from './modules/reservas/reservas.module';
import { ResenasModule } from './modules/resenas/resenas.module';
import { RespuestaResenaModule } from './modules/respuesta-resena/respuesta-resena.module';
import { CuentasAuthModule } from './modules/cuentas-auth/cuentas-auth.module';
import { OauthCuentasModule } from './modules/oauth-cuenta/oauth-cuentas.module';
import { AuthModule } from './modules/auth/auth.module';
import { InvitacionTokenModule } from './modules/invitacion-token/invitacion-token.module';
import { MailModule } from './modules/mail/mail.module';

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
    ReportesModule,
    NotificacionModule,
    VisitaModule,
    ReservasModule,
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
  providers: [AppService],
})
export class AppModule {}
