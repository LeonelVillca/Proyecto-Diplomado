import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Solicitud } from './solicitud.entity';
import { SolicitudService } from './solicitud.service';
import { SolicitudController } from './solicitud.controller';
import { Usuario } from '../usuarios/usuario.entity';
import { R2StorageService } from '../../core/storage/r2-storage.service';

@Module({
  imports: [TypeOrmModule.forFeature([Solicitud, Usuario])],
  controllers: [SolicitudController],
  providers: [SolicitudService, R2StorageService],
  exports: [SolicitudService],
})
export class SolicitudModule {}
