import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ResenasService } from './resenas.service';
import { ResenasController } from './resenas.controller';
import { Resena } from './resena.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Resena, Usuario, Restaurante])],
  controllers: [ResenasController],
  providers: [ResenasService],
  exports: [ResenasService],
})
export class ResenasModule {}
