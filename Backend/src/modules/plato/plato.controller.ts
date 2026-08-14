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
import { PlatoService } from './plato.service';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Plato } from './plato.entity';

@Controller('plato')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class PlatoController {
  constructor(private readonly platoService: PlatoService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('plato')
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

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('plato')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarPlatoDto,
  ): Promise<Plato> {
    return this.platoService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('plato')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.platoService.eliminar(id);
  }
}