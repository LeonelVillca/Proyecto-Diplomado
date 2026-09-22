import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlatoService } from './plato.service';
import { PlatoController } from './plato.controller';
import { Plato } from './plato.entity';
import { Menu } from '../menu/menu.entity';
import { CloudinaryService } from '../../core/storage/cloudinary.service';

@Module({
  imports: [TypeOrmModule.forFeature([Plato, Menu])],
  controllers: [PlatoController],
  providers: [PlatoService, CloudinaryService],
  exports: [PlatoService],
})
export class PlatoModule {}
