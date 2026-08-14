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
import { RolesService } from './roles.service';
import { CrearRolDto } from './dto/crear-rol.dto';
import { ActualizarRolDto } from './dto/actualizar-rol.dto';
import { Rol } from './rol.entity';

@Controller('roles')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin_sistema')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  crear(@Body() dto: CrearRolDto): Promise<Rol> {
    return this.rolesService.crear(dto);
  }

  @Get()
  listarTodos(): Promise<Rol[]> {
    return this.rolesService.listarTodos();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Rol> {
    return this.rolesService.buscarPorId(id);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRolDto,
  ): Promise<Rol> {
    return this.rolesService.actualizar(id, dto);
  }

  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.rolesService.eliminar(id);
  }
}
