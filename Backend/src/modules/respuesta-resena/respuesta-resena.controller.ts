import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseIntPipe,
  UseGuards,
  Req,
  ForbiddenException,
} from '@nestjs/common';
import { RespuestaResenaService } from './respuesta-resena.service';
import { CrearRespuestaResenaDto } from './dto/crear-respuesta-resena.dto';
import { ActualizarRespuestaResenaDto } from './dto/actualizar-respuesta-resena.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';

@Controller('respuesta-resena')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class RespuestaResenaController {
  constructor(private readonly respuestaResenaService: RespuestaResenaService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('respuesta_resena')
  @Post()
  crear(@Body() dto: CrearRespuestaResenaDto, @Req() req: any) {
    if (dto.idUsuarioRestaurante !== req.user.id) {
      throw new ForbiddenException('No puedes responder a nombre de otro usuario');
    }
    return this.respuestaResenaService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.respuestaResenaService.listarTodas();
  }

  // Dejamos que cualquier usuario autenticado vea las respuestas de una reseña
  @Get('resena/:idResena')
  listarPorResena(@Param('idResena', ParseIntPipe) idResena: number) {
    return this.respuestaResenaService.listarPorResena(idResena);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.respuestaResenaService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('respuesta_resena')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRespuestaResenaDto,
  ) {
    return this.respuestaResenaService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('respuesta_resena')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number) {
    return this.respuestaResenaService.eliminar(id);
  }
}
