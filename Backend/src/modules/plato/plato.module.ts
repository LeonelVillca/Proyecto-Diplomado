import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlatoService } from './plato.service';
import { PlatoController } from './plato.controller';
import { Plato } from './plato.entity';
import { Menu } from '../menu/menu.entity';
import { ImagenModule } from '../imagen/imagen.module';

@Module({
  imports: [TypeOrmModule.forFeature([Plato, Menu]), ImagenModule],
  controllers: [PlatoController],
  providers: [PlatoService],
  exports: [PlatoService],
})
export class PlatoModule {}
