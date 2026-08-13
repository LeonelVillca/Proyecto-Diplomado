import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { DocumentoAdjuntoService } from './documento-adjunto.service';
import { CrearDocumentoAdjuntoDto } from './dto/crear-documento-adjunto.dto';
import { ActualizarDocumentoAdjuntoDto } from './dto/actualizar-documento-adjunto.dto';
import { DocumentoAdjunto } from './documento-adjunto.entity';

@Controller('documento-adjunto')
export class DocumentoAdjuntoController {
  constructor(private readonly documentoAdjuntoService: DocumentoAdjuntoService) {}

  @Post()
  crear(@Body() dto: CrearDocumentoAdjuntoDto): Promise<DocumentoAdjunto> {
    return this.documentoAdjuntoService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<DocumentoAdjunto[]> {
    return this.documentoAdjuntoService.listarTodos();
  }

  @Get('solicitud/:idSolicitud')
  listarPorSolicitud(
    @Param('idSolicitud', ParseIntPipe) idSolicitud: number,
  ): Promise<DocumentoAdjunto[]> {
    return this.documentoAdjuntoService.listarPorSolicitud(idSolicitud);
  }

  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<DocumentoAdjunto> {
    return this.documentoAdjuntoService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarDocumentoAdjuntoDto,
  ): Promise<DocumentoAdjunto> {
    return this.documentoAdjuntoService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.documentoAdjuntoService.eliminar(id);
  }
}