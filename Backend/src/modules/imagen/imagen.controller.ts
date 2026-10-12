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
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { ImagenService } from './imagen.service';
import { CrearImagenDto } from './dto/crear-imagen.dto';
import { ActualizarImagenDto } from './dto/actualizar-imagen.dto';
import { Imagen } from './imagen.entity';

@Controller('imagen')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class ImagenController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly imagenService: ImagenService) {}

  // Crea una imagen.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('imagen')
  @Post()
  crear(@Body() dto: CrearImagenDto): Promise<Imagen> {
    return this.imagenService.crear(dto);
  }

  // Lista las imágenes.
  @Roles('admin_sistema')
  @Get()
  listarTodos(): Promise<Imagen[]> {
    return this.imagenService.listarTodos();
  }

  // Lista las imágenes de un restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('imagen')
  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Imagen[]> {
    return this.imagenService.listarPorRestaurante(idRestaurante);
  }

  // Busca una imagen por su identificador.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('imagen')
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Imagen> {
    return this.imagenService.buscarPorId(id);
  }

  // Actualiza una imagen.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('imagen')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarImagenDto,
  ): Promise<Imagen> {
    return this.imagenService.actualizar(id, dto);
  }

  // Elimina una imagen.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('imagen')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.imagenService.eliminar(id);
  }
}
