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
import { VisitaService } from './visita.service';
import { CrearVisitaDto } from './dto/crear-visita.dto';
import { ActualizarVisitaDto } from './dto/actualizar-visita.dto';
import { Visita } from './visita.entity';

@Controller('visita')
export class VisitaController {
  constructor(private readonly visitaService: VisitaService) {}

  @Post()
  crear(@Body() dto: CrearVisitaDto): Promise<Visita> {
    return this.visitaService.crear(dto);
  }

  @Get()
  listarTodas(): Promise<Visita[]> {
    return this.visitaService.listarTodas();
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Visita[]> {
    return this.visitaService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Visita> {
    return this.visitaService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarVisitaDto,
  ): Promise<Visita> {
    return this.visitaService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.visitaService.eliminar(id);
  }
}