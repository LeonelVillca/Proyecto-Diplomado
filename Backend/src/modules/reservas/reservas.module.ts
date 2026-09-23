import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReservasService } from './reservas.service';
import { ReservasController } from './reservas.controller';
import { Reserva } from './reserva.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Mesa } from '../mesa/mesa.entity';
import { ReservasGateway } from './reservas.gateway';
import { AuthModule } from '../auth/auth.module';
import { HorarioAtencion } from '../horario-atencion/horario-atencion.entity';
import { ExcepcionHorario } from '../horario-atencion/excepcion-horario.entity';

@Module({
  imports: [
    AuthModule,
    TypeOrmModule.forFeature([
      Reserva,
      Usuario,
      Mesa,
      HorarioAtencion,
      ExcepcionHorario,
    ]),
  ],
  controllers: [ReservasController],
  providers: [ReservasService, ReservasGateway],
  exports: [ReservasService],
})
export class ReservasModule {}
