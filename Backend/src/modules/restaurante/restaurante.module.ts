import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurante } from './restaurante.entity';
import { RestauranteService } from './restaurante.service';
import { RestauranteController } from './restaurante.controller';
import { Solicitud } from '../solicitud/solicitud.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Restaurante, Solicitud])],
  controllers: [RestauranteController],
  providers: [RestauranteService],
  exports: [RestauranteService],
})
export class RestauranteModule {}