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
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { ImagenService } from './imagen.service';
import { CrearImagenDto } from './dto/crear-imagen.dto';
import { ActualizarImagenDto } from './dto/actualizar-imagen.dto';
import { Imagen } from './imagen.entity';

@Controller('imagen')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class ImagenController {
  constructor(private readonly imagenService: ImagenService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post()
  crear(@Body() dto: CrearImagenDto): Promise<Imagen> {
    return this.imagenService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Imagen[]> {
    return this.imagenService.listarTodos();
  }

  @Get('plato/:idPlato')
  listarPorPlato(
    @Param('idPlato', ParseIntPipe) idPlato: number,
  ): Promise<Imagen[]> {
    return this.imagenService.listarPorPlato(idPlato);
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Imagen[]> {
    return this.imagenService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Imagen> {
    return this.imagenService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarImagenDto,
  ): Promise<Imagen> {
    return this.imagenService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.imagenService.eliminar(id);
  }
}