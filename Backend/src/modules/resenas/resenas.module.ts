import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ResenasService } from './resenas.service';
import { ResenasController } from './resenas.controller';
import { Resena } from './resena.entity';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { RespuestaResena } from '../respuesta-resena/respuesta-resena.entity';
import { UsuarioRol } from '../usuario-rol/usuario-rol.entity';
import { Reserva } from '../reservas/reserva.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Resena,
      Usuario,
      Restaurante,
      RespuestaResena,
      UsuarioRol,
      Reserva,
    ]),
  ],
  controllers: [ResenasController],
  providers: [ResenasService],
  exports: [ResenasService],
})
export class ResenasModule {}
