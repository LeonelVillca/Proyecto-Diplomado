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
import { NotificacionService } from './notificacion.service';
import { CrearNotificacionDto } from './dto/crear-notificacion.dto';
import { ActualizarNotificacionDto } from './dto/actualizar-notificacion.dto';
import { Notificacion } from './notificacion.entity';

@Controller('notificacion')
export class NotificacionController {
  constructor(private readonly notificacionService: NotificacionService) {}

  @Post()
  crear(@Body() dto: CrearNotificacionDto): Promise<Notificacion> {
    return this.notificacionService.crear(dto);
  }

  @Get()
  listarTodas(): Promise<Notificacion[]> {
    return this.notificacionService.listarTodas();
  }

  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Notificacion[]> {
    return this.notificacionService.listarPorUsuario(idUsuario);
  }

  @Patch(':id/leer')
  marcarLeida(@Param('id', ParseIntPipe) id: number): Promise<Notificacion> {
    return this.notificacionService.marcarLeida(id, true);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarNotificacionDto,
  ): Promise<Notificacion> {
    return this.notificacionService.actualizar(id, dto);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Notificacion> {
    return this.notificacionService.buscarPorId(id);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.notificacionService.eliminar(id);
  }
}