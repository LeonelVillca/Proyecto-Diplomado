import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RespuestaResenaService } from './respuesta-resena.service';
import { RespuestaResenaController } from './respuesta-resena.controller';
import { RespuestaResena } from './respuesta-resena.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Resena } from '../resenas/resena.entity';

@Module({
  imports: [TypeOrmModule.forFeature([RespuestaResena, Usuario, Resena])],
  controllers: [RespuestaResenaController],
  providers: [RespuestaResenaService],
  exports: [RespuestaResenaService],
})
export class RespuestaResenaModule {}
