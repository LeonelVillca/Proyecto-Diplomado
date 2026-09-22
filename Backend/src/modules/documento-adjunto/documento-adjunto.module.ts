import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DocumentoAdjunto } from './documento-adjunto.entity';
import { DocumentoAdjuntoService } from './documento-adjunto.service';
import { DocumentoAdjuntoController } from './documento-adjunto.controller';
import { Solicitud } from '../solicitud/solicitud.entity';
import { R2StorageService } from '../../core/storage/r2-storage.service';

@Module({
  imports: [TypeOrmModule.forFeature([DocumentoAdjunto, Solicitud])],
  controllers: [DocumentoAdjuntoController],
  providers: [DocumentoAdjuntoService, R2StorageService],
  exports: [DocumentoAdjuntoService],
})
export class DocumentoAdjuntoModule {}
