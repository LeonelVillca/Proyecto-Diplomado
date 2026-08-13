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
import { RestauranteService } from './restaurante.service';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { Restaurante } from './restaurante.entity';

@Controller('restaurante')
export class RestauranteController {
  constructor(private readonly restauranteService: RestauranteService) {}

  @Post()
  crear(@Body() dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.restauranteService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Restaurante[]> {
    return this.restauranteService.listarTodos();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Restaurante> {
    return this.restauranteService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRestauranteDto,
  ): Promise<Restaurante> {
    return this.restauranteService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.restauranteService.eliminar(id);
  }
}