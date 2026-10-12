import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import {
  DesregistrarDispositivoDto,
  RegistrarDispositivoDto,
} from './dto/registrar-dispositivo.dto';
import { NotificacionesService } from './notificaciones.service';

@Controller('notificaciones')
@UseGuards(JwtAuthGuard)
export class NotificacionesController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly notificaciones: NotificacionesService) {}

  // Lista las notificaciones.
  @Get()
  listar(@Req() req: { user: { id: number } }) {
    return this.notificaciones.listar(req.user.id);
  }

  // Marca una notificación como leída.
  @Patch(':id/leida')
  @HttpCode(204)
  async marcarLeida(
    @Req() req: { user: { id: number } },
    @Param('id') id: string,
  ): Promise<void> {
    if (!/^\d{1,20}$/.test(id)) throw new BadRequestException('ID inválido');
    await this.notificaciones.marcarLeida(req.user.id, id);
  }

  // Registra un dispositivo para recibir notificaciones.
  @Post('dispositivos')
  async registrar(
    @Req() req: { user: { id: number } },
    @Body() dto: RegistrarDispositivoDto,
  ) {
    await this.notificaciones.registrarDispositivo(
      req.user.id,
      dto.token,
      dto.plataforma,
    );
    return { ok: true };
  }

  // Quita el registro de un dispositivo.
  @Delete('dispositivos')
  @HttpCode(204)
  async desregistrar(
    @Req() req: { user: { id: number } },
    @Body() dto: DesregistrarDispositivoDto,
  ): Promise<void> {
    await this.notificaciones.desregistrarDispositivo(req.user.id, dto.token);
  }
}
