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

  @CheckClientOwnership('resena')
  @Get('usuario/:idUsuario')
  listarPorUsuario(@Param('idUsuario', ParseIntPipe) idUsuario: number) {
    return this.resenasService.listarPorUsuario(idUsuario);
  }
  
  @Roles('admin_sistema')
  @Get()
  listarTodas() {
    return this.resenasService.listarTodas();
  }

  @CheckClientOwnership('resena')
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.resenasService.buscarPorId(id);
  }

  @CheckClientOwnership('resena')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarResenaDto,
    @Req() req: any,
  ) {
    return this.resenasService.actualizar(id, dto, req.user?.id);
  }

  // Moderación o borrado por el propio cliente
  @CheckClientOwnership('resena')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number, @Req() req: any) {
    return this.resenasService.eliminar(id, req.user?.id);
  }
}
