import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuService } from './menu.service';
import { MenuController } from './menu.controller';
import { Menu } from './menu.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { PlatoModule } from '../plato/plato.module';

@Module({
  imports: [TypeOrmModule.forFeature([Menu, Restaurante]), PlatoModule],
  controllers: [MenuController],
  providers: [MenuService],
  exports: [MenuService],
})
export class MenuModule {}
