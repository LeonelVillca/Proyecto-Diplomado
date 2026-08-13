import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Ubicacion } from './ubicacion.entity';
import { UbicacionService } from './ubicacion.service';
import { UbicacionController } from './ubicacion.controller';
import { Restaurante } from '../restaurante/restaurante.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Ubicacion, Restaurante])],
  controllers: [UbicacionController],
  providers: [UbicacionService],
  exports: [UbicacionService],
})
export class UbicacionModule {}