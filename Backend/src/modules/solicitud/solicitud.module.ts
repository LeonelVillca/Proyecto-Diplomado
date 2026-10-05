import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Solicitud } from './solicitud.entity';
import { SolicitudService } from './solicitud.service';
import { SolicitudController } from './solicitud.controller';
import { Usuario } from '../usuarios/usuario.entity';
import { StorageModule } from '../../core/storage/storage.module';

@Module({
  imports: [StorageModule, TypeOrmModule.forFeature([Solicitud, Usuario])],
  controllers: [SolicitudController],
  providers: [SolicitudService],
  exports: [SolicitudService],
})
export class SolicitudModule {}
