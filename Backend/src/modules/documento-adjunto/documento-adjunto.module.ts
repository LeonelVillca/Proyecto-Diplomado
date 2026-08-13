import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DocumentoAdjunto } from './documento-adjunto.entity';
import { DocumentoAdjuntoService } from './documento-adjunto.service';
import { DocumentoAdjuntoController } from './documento-adjunto.controller';
import { Solicitud } from '../solicitud/solicitud.entity';

@Module({
  imports: [TypeOrmModule.forFeature([DocumentoAdjunto, Solicitud])],
  controllers: [DocumentoAdjuntoController],
  providers: [DocumentoAdjuntoService],
  exports: [DocumentoAdjuntoService],
})
export class DocumentoAdjuntoModule {}