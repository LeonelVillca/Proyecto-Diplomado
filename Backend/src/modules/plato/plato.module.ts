import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Plato } from './plato.entity';
import { PlatoService } from './plato.service';
import { PlatoController } from './plato.controller';
import { Menu } from '../menu/menu.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Plato, Menu])],
  controllers: [PlatoController],
  providers: [PlatoService],
  exports: [PlatoService],
})
export class PlatoModule {}