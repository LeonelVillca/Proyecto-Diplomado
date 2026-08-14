import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReservasService } from './reservas.service';
import { ReservasController } from './reservas.controller';
import { Reserva } from './reserva.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Mesa } from '../mesa/mesa.entity';
import { ReservasGateway } from './reservas.gateway';

@Module({
  imports: [TypeOrmModule.forFeature([Reserva, Usuario, Mesa])],
  controllers: [ReservasController],
  providers: [ReservasService, ReservasGateway],
  exports: [ReservasService],
})
export class ReservasModule {}
