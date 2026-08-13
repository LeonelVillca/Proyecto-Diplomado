import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CategoriaSoporte } from './categoria-soporte.entity';
import { CategoriaSoporteService } from './categoria-soporte.service';
import { CategoriaSoporteController } from './categoria-soporte.controller';

@Module({
  imports: [TypeOrmModule.forFeature([CategoriaSoporte])],
  controllers: [CategoriaSoporteController],
  providers: [CategoriaSoporteService],
  exports: [CategoriaSoporteService],
})
export class CategoriaSoporteModule {}