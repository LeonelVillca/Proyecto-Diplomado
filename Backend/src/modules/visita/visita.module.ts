import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Visita } from './visita.entity';
import { VisitaService } from './visita.service';
import { VisitaController } from './visita.controller';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Usuario } from '../usuarios/usuario.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Visita, Restaurante, Usuario])],
  controllers: [VisitaController],
  providers: [VisitaService],
  exports: [VisitaService],
})
export class VisitaModule {}