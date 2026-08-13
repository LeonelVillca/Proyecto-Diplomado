import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Soporte } from './soporte.entity';
import { SoporteService } from './soporte.service';
import { SoporteController } from './soporte.controller';
import { Usuario } from '../usuarios/usuario.entity';
import { CategoriaSoporte } from '../categoria-soporte/categoria-soporte.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Soporte, Usuario, CategoriaSoporte])],
  controllers: [SoporteController],
  providers: [SoporteService],
  exports: [SoporteService],
})
export class SoporteModule {}