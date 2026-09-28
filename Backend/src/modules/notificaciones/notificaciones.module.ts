import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Usuario } from '../usuarios/usuario.entity';
import { Reserva } from '../reservas/reserva.entity';
import { DispositivoPush } from './dispositivo-push.entity';
import { Notificacion } from './notificacion.entity';
import { NotificacionesController } from './notificaciones.controller';
import { NotificacionesService } from './notificaciones.service';

@Module({
  imports: [
    AuthModule,
    TypeOrmModule.forFeature([Notificacion, DispositivoPush, Usuario, Reserva]),
  ],
  controllers: [NotificacionesController],
  providers: [NotificacionesService],
  exports: [NotificacionesService],
})
export class NotificacionesModule {}
