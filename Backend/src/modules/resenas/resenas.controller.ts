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
import { ResenasService } from './resenas.service';
import { CrearResenaDto } from './dto/crear-resena.dto';
import { ActualizarResenaDto } from './dto/actualizar-resena.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { ClientOwnershipGuard, CheckClientOwnership } from '../../core/guards/client-ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';

@Controller('resenas')
@UseGuards(JwtAuthGuard, RolesGuard, ClientOwnershipGuard)
export class ResenasController {
  constructor(private readonly resenasService: ResenasService) {}

  @CheckClientOwnership('resena')
  @Post()
  crear(@Body() dto: CrearResenaDto) {
    return this.resenasService.crear(dto);
  }

  // Dejamos que los clientes puedan listar reseñas de un restaurante
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(@Param('idRestaurante', ParseIntPipe) idRestaurante: number) {
    return this.resenasService.listarPorRestaurante(idRestaurante);
  }
  
  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.resenasService.listarTodas();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.resenasService.buscarPorId(id);
  }

  @CheckClientOwnership('resena')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarResenaDto,
  ) {
    return this.resenasService.actualizar(id, dto);
  }

  // Moderación o borrado por el propio cliente
  @CheckClientOwnership('resena')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number) {
    return this.resenasService.eliminar(id);
  }
}
