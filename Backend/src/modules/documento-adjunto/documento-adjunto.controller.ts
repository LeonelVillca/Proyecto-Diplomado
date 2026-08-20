import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Res,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import type { Response } from 'express';
import * as path from 'path';
import * as fs from 'fs';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
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

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin_sistema')
  @Get('privado/:idSolicitud/:filename')
  servirDocumentoPrivado(
    @Param('idSolicitud', ParseIntPipe) idSolicitud: number,
    @Param('filename') filename: string,
    @Res() res: any,
  ) {
    console.log(`[DocumentoAdjunto] Solicitud de archivo: ${filename} para solicitud ${idSolicitud}`);
    const filePath = path.join(process.cwd(), 'storage', 'privado', 'solicitudes', idSolicitud.toString(), filename);
    if (!fs.existsSync(filePath)) {
      console.log(`[DocumentoAdjunto] Archivo no encontrado en disco: ${filePath}`);
      return res.status(404).json({ message: 'El documento solicitado no existe' });
    }
    return res.sendFile(filePath);
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