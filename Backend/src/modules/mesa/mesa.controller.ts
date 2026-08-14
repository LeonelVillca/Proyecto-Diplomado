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
import { MesaService } from './mesa.service';
import { CrearMesaDto } from './dto/crear-mesa.dto';
import { ActualizarMesaDto } from './dto/actualizar-mesa.dto';
import { Mesa } from './mesa.entity';

@Controller('mesa')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class MesaController {
  constructor(private readonly mesaService: MesaService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Post()
  crear(@Body() dto: CrearMesaDto): Promise<Mesa> {
    return this.mesaService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Mesa[]> {
    return this.mesaService.listarTodos();
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Mesa[]> {
    return this.mesaService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Mesa> {
    return this.mesaService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarMesaDto,
  ): Promise<Mesa> {
    return this.mesaService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('mesa')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.mesaService.eliminar(id);
  }
}