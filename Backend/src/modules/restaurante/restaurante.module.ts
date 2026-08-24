import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurante } from './restaurante.entity';
import { RestauranteService } from './restaurante.service';
import { RestauranteController } from './restaurante.controller';
import { Solicitud } from '../solicitud/solicitud.entity';
import { Ubicacion } from '../ubicacion/ubicacion.entity';
import { HorarioAtencion } from '../horario-atencion/horario-atencion.entity';
import { Mesa } from '../mesa/mesa.entity';
import { Imagen } from '../imagen/imagen.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Restaurante, Solicitud, Ubicacion, HorarioAtencion, Mesa, Imagen])],
  controllers: [RestauranteController],
  providers: [RestauranteService],
  exports: [RestauranteService],
})
export class RestauranteModule {}