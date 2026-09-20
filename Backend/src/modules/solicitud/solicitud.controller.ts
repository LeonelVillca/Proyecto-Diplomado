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
  BadRequestException,
  ConflictException,
  Header,
  HttpCode,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { SolicitudService } from './solicitud.service';
import { CrearSolicitudDto } from './dto/crear-solicitud.dto';
import { ActualizarSolicitudDto } from './dto/actualizar-solicitud.dto';
import { Solicitud } from './solicitud.entity';
import { Throttle } from '@nestjs/throttler';
import { ReenviarVerificacionDto } from './dto/reenviar-verificacion.dto';

@Controller('solicitud')
export class SolicitudController {
  constructor(private readonly solicitudService: SolicitudService) { }

  @Get('verificar-correo')
  @Header('Content-Type', 'text/html; charset=utf-8')
  @Header('Cache-Control', 'no-store')
  @Header('Referrer-Policy', 'no-referrer')
  @Throttle({ default: { limit: 10, ttl: 60 * 60 * 1000 } })
  mostrarConfirmacion(@Query('token') token: string): string {
    if (!/^[a-f0-9]{64}$/i.test(token ?? '')) {
      throw new BadRequestException('Enlace de verificación inválido.');
    }
    return `<!doctype html><html lang="es"><meta charset="utf-8"><title>Confirmar correo</title><body style="font-family:sans-serif;max-width:38rem;margin:4rem auto;padding:1rem"><h1>Confirma tu correo</h1><p>Pulsa el botón para que podamos revisar tu solicitud.</p><form method="post" action="/api/v1/solicitud/confirmar-correo"><input type="hidden" name="token" value="${token}"><button type="submit">Confirmar correo</button></form></body></html>`;
  }

  @Post('confirmar-correo')
  @HttpCode(200)
  @Header('Content-Type', 'text/html; charset=utf-8')
  @Header('Cache-Control', 'no-store')
  @Header('Referrer-Policy', 'no-referrer')
  @Throttle({ default: { limit: 10, ttl: 60 * 60 * 1000 } })
  async verificarCorreo(@Body('token') token: string): Promise<string> {
    await this.solicitudService.verificarCorreo(token);
    return '<!doctype html><html lang="es"><meta charset="utf-8"><title>Correo confirmado</title><body style="font-family:sans-serif;max-width:38rem;margin:4rem auto;padding:1rem"><h1>Correo confirmado</h1><p>Tu solicitud ya puede ser revisada. Puedes cerrar esta página.</p></body></html>';
  }

  @Post('reenviar-verificacion')
  @HttpCode(200)
  @Throttle({ default: { limit: 3, ttl: 60 * 60 * 1000 } })
  reenviarVerificacion(@Body() dto: ReenviarVerificacionDto) {
    return this.solicitudService.reenviarVerificacion(dto.correo);
  }

  @Post()
  // El formulario de alta es público; limitarlo con más rigor que el resto de la API.
  @Throttle({ default: { limit: 3, ttl: 60 * 60 * 1000 } })
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'documentoNit', maxCount: 1 },
      { name: 'documentoCi', maxCount: 1 },
    ], {
      limits: { fileSize: 5 * 1024 * 1024, files: 2, fields: 20, fieldSize: 16 * 1024, parts: 22 },
      fileFilter: (_req, file, callback) => {
        const allowed = ['application/pdf', 'image/jpeg', 'image/png'];
        if (allowed.includes(file.mimetype)) {
          callback(null, true);
        } else {
          callback(new BadRequestException('Los documentos deben ser PDF, JPG o PNG.'), false);
        }
      },
    }),
  )
  crear(
    @Body() dto: CrearSolicitudDto,
    @UploadedFiles() files: { documentoNit?: Express.Multer.File[]; documentoCi?: Express.Multer.File[] },
  ): Promise<{ mensaje: string }> {
    return this.solicitudService.crear(dto, files)
      .then(() => ({ mensaje: 'Si la solicitud puede procesarse, recibirás un enlace de confirmación.' }))
      .catch((error) => {
        // No revelar por la respuesta pública si un correo ya tiene una solicitud pendiente.
        if (error instanceof ConflictException) {
          return { mensaje: 'Si la solicitud puede procesarse, recibirás un enlace de confirmación.' };
        }
        throw error;
      });
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
  @Roles('admin_sistema')
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
