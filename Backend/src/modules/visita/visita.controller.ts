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
import { VisitaService } from './visita.service';
import { CrearVisitaDto } from './dto/crear-visita.dto';
import { ActualizarVisitaDto } from './dto/actualizar-visita.dto';
import { Visita } from './visita.entity';

@Controller('visita')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
@Roles('admin_restaurante', 'admin_sistema')
export class VisitaController {
  constructor(private readonly visitaService: VisitaService) {}

  @Post()
  @CheckOwnership('visita')
  crear(@Body() dto: CrearVisitaDto): Promise<Visita> {
    return this.visitaService.crear(dto);
  }

  @Get()
  @Roles('admin_sistema')
  listarTodas(): Promise<Visita[]> {
    return this.visitaService.listarTodas();
  }

  @Get('restaurante/:idRestaurante')
  @CheckOwnership('visita')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Visita[]> {
    return this.visitaService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  @CheckOwnership('visita')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Visita> {
    return this.visitaService.buscarPorId(id);
  }

  @Patch(':id')
  @CheckOwnership('visita')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarVisitaDto,
  ): Promise<Visita> {
    return this.visitaService.actualizar(id, dto);
  }

  @Delete(':id')
  @CheckOwnership('visita')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.visitaService.eliminar(id);
  }
}
