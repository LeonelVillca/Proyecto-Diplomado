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
import { Roles } from '../../core/decorators/roles.decorator';
import { CategoriaSoporteService } from './categoria-soporte.service';
import { CrearCategoriaSoporteDto } from './dto/crear-categoria-soporte.dto';
import { ActualizarCategoriaSoporteDto } from './dto/actualizar-categoria-soporte.dto';
import { CategoriaSoporte } from './categoria-soporte.entity';

@Controller('categoria-soporte')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class CategoriaSoporteController {
  constructor(private readonly categoriaSoporteService: CategoriaSoporteService) {}

  @Post()
  crear(@Body() dto: CrearCategoriaSoporteDto): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.crear(dto);
  }

  @Roles()
  @Get()
  listarTodas(): Promise<CategoriaSoporte[]> {
    return this.categoriaSoporteService.listarTodas();
  }

  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarCategoriaSoporteDto,
  ): Promise<CategoriaSoporte> {
    return this.categoriaSoporteService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.categoriaSoporteService.eliminar(id);
  }
}