import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlatoService } from './plato.service';
import { PlatoController } from './plato.controller';
import { Plato } from './plato.entity';
import { Menu } from '../menu/menu.entity';
import { StorageModule } from '../../core/storage/storage.module';

@Module({
  imports: [StorageModule, TypeOrmModule.forFeature([Plato, Menu])],
  controllers: [PlatoController],
  providers: [PlatoService],
  exports: [PlatoService],
})
export class PlatoModule {}
