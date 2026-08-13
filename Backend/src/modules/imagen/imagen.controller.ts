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
import { ImagenService } from './imagen.service';
import { CrearImagenDto } from './dto/crear-imagen.dto';
import { ActualizarImagenDto } from './dto/actualizar-imagen.dto';
import { Imagen } from './imagen.entity';

@Controller('imagen')
export class ImagenController {
  constructor(private readonly imagenService: ImagenService) {}

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

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarImagenDto,
  ): Promise<Imagen> {
    return this.imagenService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.imagenService.eliminar(id);
  }
}