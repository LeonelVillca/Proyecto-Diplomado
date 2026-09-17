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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { RestauranteService } from './restaurante.service';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { Restaurante } from './restaurante.entity';

@Controller('restaurante')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class RestauranteController {
  constructor(private readonly restauranteService: RestauranteService) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post()
  crear(@Body() dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.restauranteService.crear(dto);
  }

  @Get('ranking')
  obtenerRanking(
    @Query('orden') orden: 'calificacion' | 'visitas' = 'calificacion',
    @Query('limite') limite?: string,
  ): Promise<any[]> {
    const limiteNumero = limite === undefined ? undefined : Number(limite);
    return this.restauranteService.obtenerRanking(orden, limiteNumero);
  }

  @Get()
  listarTodos(): Promise<any[]> {
    return this.restauranteService.listarTodos();
  }

  @Roles('admin_restaurante')
  @Get('mis-restaurantes')
  listarMisRestaurantes(@Req() req: any): Promise<Restaurante[]> {
    return this.restauranteService.listarPorUsuario(req.user.id);
  }
  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number): Promise<Restaurante> {
    return this.restauranteService.buscarPorId(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ActualizarRestauranteDto,
  ): Promise<Restaurante> {
    return this.restauranteService.actualizar(id, dto);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.restauranteService.eliminar(id);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/portada')
  @UseInterceptors(FileInterceptor('file'))
  subirPortada(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Restaurante> {
    return this.restauranteService.subirPortada(id, file);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/logo')
  @UseInterceptors(FileInterceptor('file'))
  subirLogo(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Restaurante> {
    return this.restauranteService.subirLogo(id, file);
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('restaurante')
  @Post(':id/galeria')
  @UseInterceptors(FilesInterceptor('files', 10))
  subirGaleria(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<Restaurante> {
    return this.restauranteService.subirGaleria(id, files);
  }
}
