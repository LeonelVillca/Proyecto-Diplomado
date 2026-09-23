import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HorarioAtencion } from './horario-atencion.entity';
import { HorarioAtencionService } from './horario-atencion.service';
import { HorarioAtencionController } from './horario-atencion.controller';
import { Restaurante } from '../restaurante/restaurante.entity';
import { ExcepcionHorario } from './excepcion-horario.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([HorarioAtencion, ExcepcionHorario, Restaurante]),
  ],
  controllers: [HorarioAtencionController],
  providers: [HorarioAtencionService],
  exports: [HorarioAtencionService],
})
export class HorarioAtencionModule {}
