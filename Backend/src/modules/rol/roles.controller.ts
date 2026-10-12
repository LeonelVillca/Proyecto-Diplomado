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
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
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
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly rolesService: RolesService) {}

  // Crea un rol.
  @Post()
  crear(@Body() dto: CrearRolDto): Promise<Rol> {
    return this.rolesService.crear(dto);
  }

  // Lista los roles.
  @Get()
  listarTodos(): Promise<Rol[]> {
    return this.rolesService.listarTodos();
  }

  // Busca un rol por su identificador.
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Rol> {
    return this.rolesService.buscarPorId(id);
  }

  // Actualiza un rol.
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRolDto,
  ): Promise<Rol> {
    return this.rolesService.actualizar(id, dto);
  }

  // Elimina un rol.
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.rolesService.eliminar(id);
  }
}
