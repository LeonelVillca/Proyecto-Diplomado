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
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { DocumentoAdjuntoService } from './documento-adjunto.service';
import { CrearDocumentoAdjuntoDto } from './dto/crear-documento-adjunto.dto';
import { ActualizarDocumentoAdjuntoDto } from './dto/actualizar-documento-adjunto.dto';
import { DocumentoAdjunto } from './documento-adjunto.entity';
import { R2StorageService } from '../../core/storage/r2-storage.service';

@Controller('documento-adjunto')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class DocumentoAdjuntoController {
  constructor(
    private readonly documentoAdjuntoService: DocumentoAdjuntoService,
    private readonly r2Storage: R2StorageService,
  ) {}

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

  @Get('privado/:idSolicitud/:filename')
  async servirDocumentoPrivado(
    @Param('idSolicitud', ParseIntPipe) idSolicitud: number,
    @Param('filename') filename: string,
    @Res() res: any,
  ): Promise<any> {
    if (filename !== filename.replace(/[^a-zA-Z0-9._-]/g, '') || filename.includes('..')) {
      return res.status(400).json({ message: 'Nombre de archivo no válido' });
    }
    res.setHeader('Cache-Control', 'private, no-store');
    res.setHeader('Content-Security-Policy', "sandbox; default-src 'none'");
    const url = await this.r2Storage.signedDownloadUrl(`solicitudes/${idSolicitud}/${filename}`);
    return res.redirect(url);
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
