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
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { randomUUID } from 'crypto';
import { imageUploadOptions, sanitizeImage } from '../../core/security/uploads';
import { CloudinaryService } from '../../core/storage/cloudinary.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import {
  OwnershipGuard,
  CheckOwnership,
} from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { PlatoService } from './plato.service';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Plato } from './plato.entity';

@Controller('plato')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class PlatoController {
  constructor(
    private readonly platoService: PlatoService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @Post('restaurante/:idRestaurante/foto')
  @CheckOwnership('plato')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async uploadFoto(
    @UploadedFile() file: Express.Multer.File,
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ): Promise<{ url: string }> {
    if (!idRestaurante)
      throw new BadRequestException('idRestaurante is required');
    if (!file) throw new BadRequestException('Se requiere una imagen');

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException(
        'El archivo debe ser una imagen válida (JPG/PNG/WEBP)',
      );
    }

    if (!Number.isSafeInteger(idRestaurante) || idRestaurante < 1)
      throw new BadRequestException('Restaurante inválido');
    const uploaded = await this.cloudinaryService.uploadWebp(
      await sanitizeImage(file),
      `mesachapaca/restaurantes/${idRestaurante}/platos`,
      randomUUID(),
    );
    return { url: uploaded.secure_url };
  }

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
