import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { ClientOwnershipGuard, CheckClientOwnership } from '../../core/guards/client-ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { NotificacionService } from './notificacion.service';
import { CrearNotificacionDto } from './dto/crear-notificacion.dto';
import { ActualizarNotificacionDto } from './dto/actualizar-notificacion.dto';
import { Notificacion } from './notificacion.entity';

@Controller('notificacion')
@UseGuards(JwtAuthGuard, RolesGuard, ClientOwnershipGuard)
export class NotificacionController {
  constructor(private readonly notificacionService: NotificacionService) {}

  @Roles('admin_sistema')
  @Post()
  crear(@Body() dto: CrearNotificacionDto): Promise<Notificacion> {
    return this.notificacionService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodas(): Promise<Notificacion[]> {
    return this.notificacionService.listarTodas();
  }

  @CheckClientOwnership('notificacion')
  @Get('usuario/:idUsuario')
  listarPorUsuario(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
  ): Promise<Notificacion[]> {
    return this.notificacionService.listarPorUsuario(idUsuario);
  }

  @CheckClientOwnership('notificacion')
  @Patch(':id/leer')
  marcarLeida(@Param('id', ParseIntPipe) id: number): Promise<Notificacion> {
    return this.notificacionService.marcarLeida(id, true);
  }

  @Roles('admin_sistema')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarNotificacionDto,
  ): Promise<Notificacion> {
    return this.notificacionService.actualizar(id, dto);
  }

  @CheckClientOwnership('notificacion')
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Notificacion> {
    return this.notificacionService.buscarPorId(id);
  }

  @Roles('admin_sistema')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.notificacionService.eliminar(id);
  }
}