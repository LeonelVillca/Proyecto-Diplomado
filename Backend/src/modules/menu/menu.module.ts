import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Menu } from './menu.entity';
import { MenuService } from './menu.service';
import { MenuController } from './menu.controller';
import { Restaurante } from '../restaurante/restaurante.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Menu, Restaurante])],
  controllers: [MenuController],
  providers: [MenuService],
  exports: [MenuService],
})
export class MenuModule {}