import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DocumentoAdjunto } from './documento-adjunto.entity';
import { DocumentoAdjuntoService } from './documento-adjunto.service';
import { DocumentoAdjuntoController } from './documento-adjunto.controller';
import { Solicitud } from '../solicitud/solicitud.entity';
import { StorageModule } from '../../core/storage/storage.module';

@Module({
  imports: [
    StorageModule,
    TypeOrmModule.forFeature([DocumentoAdjunto, Solicitud]),
  ],
  controllers: [DocumentoAdjuntoController],
  providers: [DocumentoAdjuntoService],
  exports: [DocumentoAdjuntoService],
})
export class DocumentoAdjuntoModule {}
