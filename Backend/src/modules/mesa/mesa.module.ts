import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Mesa } from './mesa.entity';
import { MesaService } from './mesa.service';
import { MesaController } from './mesa.controller';
import { Restaurante } from '../restaurante/restaurante.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Mesa, Restaurante])],
  controllers: [MesaController],
  providers: [MesaService],
  exports: [MesaService],
})
export class MesaModule {}