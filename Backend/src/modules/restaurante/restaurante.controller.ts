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
  Req,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  Query,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/security/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { RestauranteService } from './restaurante.service';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { Restaurante } from './restaurante.entity';
import { RestaurantePublicoRespuesta } from './queries/restaurante-consultas.service';
import { imageUploadOptions } from '../../core/security/uploads';

@Controller('restaurante')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class RestauranteController {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(private readonly restauranteService: RestauranteService) {}

  // Crea el perfil de un restaurante.
  @Roles('admin_sistema')
  @Post()
  crear(@Body() dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.restauranteService.crear(dto);
  }

  // Obtiene el ranking de restaurantes.
  @Get('ranking')
  obtenerRanking(@Query('limite') limite?: string): Promise<any[]> {
    const limiteNumero = limite === undefined ? undefined : Number(limite);
    return this.restauranteService.obtenerRanking(limiteNumero);
  }

  // Lista los tipos de comida disponibles.
  @Get('tipos-comida')
  listarTiposComida() {
    return this.restauranteService.listarTiposComida();
  }

  // Lista restaurantes para la administración del sistema.
  @Roles('admin_sistema')
  @Get('admin/listado')
  listarParaAdministrador(): Promise<any[]> {
    return this.restauranteService.listarParaAdministrador();
  }

  // Cambia el estado de un restaurante desde administración.
  @Roles('admin_sistema')
  @Patch('admin/:id/estado')
  cambiarEstadoComoAdministrador(
    @Param('id', ParseIntPipe) id: number,
    @Body('estado') estado: boolean,
  ): Promise<any> {
    return this.restauranteService.cambiarEstadoComoAdministrador(id, estado);
  }

  // Lista los restaurantes.
  @Get()
  listarTodos(): Promise<any[]> {
    return this.restauranteService.listarTodos();
  }

  // Lista los restaurantes del usuario autenticado.
  @Roles('admin_restaurante')
  @Get('mis-restaurantes')
  listarMisRestaurantes(@Req() req: any): Promise<Restaurante[]> {
    return this.restauranteService.listarPorUsuario(req.user.id);
  }
  // Busca un restaurante por su identificador.
  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<RestaurantePublicoRespuesta> {
    return this.restauranteService.buscarPorIdPublico(id);
  }

  // Actualiza un restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRestauranteDto,
  ): Promise<Restaurante> {
    return this.restauranteService.actualizar(id, dto);
  }

  // Elimina un restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.restauranteService.eliminar(id);
  }

  // Sube la imagen de portada del restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/portada')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  subirPortada(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Restaurante> {
    return this.restauranteService.subirPortada(id, file);
  }

  // Sube el logotipo del restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/logo')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  subirLogo(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Restaurante> {
    return this.restauranteService.subirLogo(id, file);
  }

  // Sube imágenes a la galería del restaurante.
  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/galeria')
  @UseInterceptors(FilesInterceptor('files', 10, imageUploadOptions))
  subirGaleria(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<Restaurante> {
    return this.restauranteService.subirGaleria(id, files);
  }
}
