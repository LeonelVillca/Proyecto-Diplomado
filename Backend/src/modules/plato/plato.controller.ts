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
import { PlatoService } from './plato.service';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Plato } from './plato.entity';

@Controller('plato')
export class PlatoController {
  constructor(private readonly platoService: PlatoService) {}

  @Post()
  crear(@Body() dto: CrearPlatoDto): Promise<Plato> {
    return this.platoService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Plato[]> {
    return this.platoService.listarTodos();
  }

  @Get('menu/:idMenu')
  listarPorMenu(
    @Param('idMenu', ParseIntPipe) idMenu: number,
  ): Promise<Plato[]> {
    return this.platoService.listarPorMenu(idMenu);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Plato> {
    return this.platoService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarPlatoDto,
  ): Promise<Plato> {
    return this.platoService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.platoService.eliminar(id);
  }
}