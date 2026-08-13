import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Imagen } from './imagen.entity';
import { ImagenService } from './imagen.service';
import { ImagenController } from './imagen.controller';
import { Plato } from '../plato/plato.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Imagen, Plato, Restaurante])],
  controllers: [ImagenController],
  providers: [ImagenService],
  exports: [ImagenService],
})
export class ImagenModule {}