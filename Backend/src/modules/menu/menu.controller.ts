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
import { MenuService } from './menu.service';
import { CrearMenuDto } from './dto/crear-menu.dto';
import { ActualizarMenuDto } from './dto/actualizar-menu.dto';
import { Menu } from './menu.entity';

@Controller('menu')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class MenuController {
  constructor(private readonly menuService: MenuService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('menu')
  @Post()
  crear(@Body() dto: CrearMenuDto): Promise<Menu> {
    return this.menuService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Menu[]> {
    return this.menuService.listarTodos();
  }

  @Get('restaurante/:idRestaurante')
  listarPorRestaurante(
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<Menu[]> {
    return this.menuService.listarPorRestaurante(idRestaurante);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Menu> {
    return this.menuService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('menu')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarMenuDto,
  ): Promise<Menu> {
    return this.menuService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('menu')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.menuService.eliminar(id);
  }
}