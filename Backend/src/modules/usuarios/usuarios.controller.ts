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
import { UsuariosService } from './usuarios.service';
import { CrearUsuarioDto } from './dto/crear-usuario.dto';
import { ActualizarUsuarioDto } from './dto/actualizar-usuario.dto';
import { Usuario } from './usuario.entity';

@Controller('usuarios')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsuariosController {
  constructor(private readonly usuariosService: UsuariosService) {}

  @Post()
  crear(@Body() dto: CrearUsuarioDto): Promise<Usuario> {
    return this.usuariosService.crear(dto);
  }

  @Roles('admin_sistema')
  @Get()
  listarTodos(): Promise<Usuario[]> {
    return this.usuariosService.listarTodos();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Usuario> {
    return this.usuariosService.buscarPorId(id);
  }

  @Roles('admin_sistema')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarUsuarioDto,
  ): Promise<Usuario> {
    return this.usuariosService.actualizar(id, dto);
  }

  @Roles('admin_sistema')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.usuariosService.eliminar(id);
  }
}
