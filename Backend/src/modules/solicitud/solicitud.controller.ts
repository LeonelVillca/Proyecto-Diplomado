import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { SolicitudService } from './solicitud.service';
import { CrearSolicitudDto } from './dto/crear-solicitud.dto';
import { ActualizarSolicitudDto } from './dto/actualizar-solicitud.dto';
import { Solicitud } from './solicitud.entity';

@Controller('solicitud')
export class SolicitudController {
  constructor(private readonly solicitudService: SolicitudService) { }

  @Post()
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'documentoNit', maxCount: 1 },
      { name: 'documentoCi', maxCount: 1 },
    ], {
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, callback) => {
        const allowed = ['application/pdf', 'image/jpeg', 'image/png'];
        if (allowed.includes(file.mimetype)) {
          callback(null, true);
        } else {
          callback(new Error('Los documentos deben ser PDF, JPG o PNG.'), false);
        }
      },
    }),
  )
  crear(
    @Body() dto: CrearSolicitudDto,
    @UploadedFiles() files: { documentoNit?: Express.Multer.File[]; documentoCi?: Express.Multer.File[] },
  ): Promise<Solicitud> {
    return this.solicitudService.crear(dto, files);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin_sistema')
  @Get()
  listarTodos(@Query('estado') estado?: string): Promise<Solicitud[]> {
    return this.solicitudService.listarTodos(estado);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin_sistema')
  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Solicitud[]> {
    return this.solicitudService.listarPorUsuario(idUsuario);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Solicitud> {
    return this.solicitudService.buscarPorId(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin_sistema')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarSolicitudDto,
  ): Promise<Solicitud> {
    return this.solicitudService.actualizar(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin_sistema')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.solicitudService.eliminar(id);
  }
}
