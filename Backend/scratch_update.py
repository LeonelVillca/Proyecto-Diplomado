import os

def update_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Update menu.service.ts
menu_service_content = """import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Menu } from './menu.entity';
import { CrearMenuDto } from './dto/crear-menu.dto';
import { ActualizarMenuDto } from './dto/actualizar-menu.dto';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Plato } from '../plato/plato.entity';

@Injectable()
export class MenuService {
  constructor(
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
    @InjectRepository(Plato)
    private readonly platoRepository: Repository<Plato>,
  ) {}

  async crear(dto: CrearMenuDto): Promise<Menu> {
    const restaurante = await this.restauranteRepository.findOneBy({
      id: dto.idRestaurante,
    });
    if (!restaurante) {
      throw new NotFoundException(`Restaurante con id ${dto.idRestaurante} no encontrado`);
    }

    const { idRestaurante, platos, ...datos } = dto;
    const menu = this.menuRepository.create({ ...datos, restaurante });
    const savedMenu = await this.menuRepository.save(menu);

    if (platos && platos.length > 0) {
      const platosEntities = platos.map(p => this.platoRepository.create({ ...p, menu: savedMenu }));
      await this.platoRepository.save(platosEntities);
    }

    return this.buscarPorId(savedMenu.id);
  }

  listarTodos(): Promise<Menu[]> {
    return this.menuRepository.find({ relations: { restaurante: true, platos: true } });
  }

  async buscarPorId(id: number): Promise<Menu> {
    const menu = await this.menuRepository.findOne({
      where: { id },
      relations: { restaurante: true, platos: true },
    });
    if (!menu) {
      throw new NotFoundException(`Menú con id ${id} no encontrado`);
    }
    return menu;
  }

  listarPorRestaurante(idRestaurante: number): Promise<Menu[]> {
    return this.menuRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true, platos: true },
    });
  }

  async actualizar(id: number, dto: ActualizarMenuDto): Promise<Menu> {
    const menu = await this.buscarPorId(id);
    const { platos, ...datos } = dto as any;
    
    Object.assign(menu, datos);
    await this.menuRepository.save(menu);

    if (platos) {
      // Very basic sync: delete existing and insert new
      await this.platoRepository.delete({ menu: { id } });
      if (platos.length > 0) {
        const platosEntities = platos.map(p => this.platoRepository.create({ ...p, menu }));
        await this.platoRepository.save(platosEntities);
      }
    }

    return this.buscarPorId(id);
  }

  async eliminar(id: number): Promise<void> {
    const menu = await this.buscarPorId(id);
    await this.menuRepository.delete(menu.id);
  }
}
"""

# 2. Update crear-menu.dto.ts
crear_menu_dto_content = """import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
  IsArray,
} from 'class-validator';

export class PlatoDetalleDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  nombre: string;

  @Type(() => Number)
  @Min(0)
  precio: number;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsString()
  fotoUrl?: string;

  @IsOptional()
  @IsBoolean()
  disponible?: boolean;
}

export class CrearMenuDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  descripcion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  tipo?: string;

  @IsOptional()
  @IsBoolean()
  disponibilidad?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlatoDetalleDto)
  platos?: PlatoDetalleDto[];
}
"""

# 3. Update menu.controller.ts (add PATCH disponibilidad)
menu_controller_content = """import {
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
  @Patch(':id/disponibilidad')
  async cambiarDisponibilidad(
    @Param('id', ParseIntPipe) id: number,
    @Body('disponibilidad') disponibilidad: boolean,
  ): Promise<Menu> {
    return this.menuService.actualizar(id, { disponibilidad });
  }

  @Roles('admin_restaurante', 'admin_sistema')
  @CheckOwnership('menu')
  @Delete(':id')
  eliminar(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.menuService.eliminar(id);
  }
}
"""

# 4. Update plato.controller.ts (add POST upload-foto)
plato_controller_content = """import {
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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { OwnershipGuard, CheckOwnership } from '../../core/guards/ownership.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { PlatoService } from './plato.service';
import { CrearPlatoDto } from './dto/crear-plato.dto';
import { ActualizarPlatoDto } from './dto/actualizar-plato.dto';
import { Plato } from './plato.entity';
import { ImagenService } from '../imagen/imagen.service';

@Controller('plato')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class PlatoController {
  constructor(
    private readonly platoService: PlatoService,
    private readonly imagenService: ImagenService
  ) {}

  @Roles('admin_restaurante', 'admin_sistema')
  @Post('upload-foto')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFoto(
    @UploadedFile() file: Express.Multer.File,
    @Body('idRestaurante') idRestaurante: string
  ): Promise<{ url: string }> {
    if (!idRestaurante) throw new Error('idRestaurante is required');
    const filename = `restaurantes/${idRestaurante}/platos/${Date.now()}`;
    const url = await this.imagenService.procesarYSubirWebp(file, filename);
    return { url };
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
"""

# 5. Update menu.module.ts
menu_module_content = """import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuService } from './menu.service';
import { MenuController } from './menu.controller';
import { Menu } from './menu.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Plato } from '../plato/plato.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Menu, Restaurante, Plato])],
  controllers: [MenuController],
  providers: [MenuService],
  exports: [MenuService],
})
export class MenuModule {}
"""

# 6. Update plato.module.ts
plato_module_content = """import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlatoService } from './plato.service';
import { PlatoController } from './plato.controller';
import { Plato } from './plato.entity';
import { Menu } from '../menu/menu.entity';
import { ImagenModule } from '../imagen/imagen.module';

@Module({
  imports: [TypeOrmModule.forFeature([Plato, Menu]), ImagenModule],
  controllers: [PlatoController],
  providers: [PlatoService],
  exports: [PlatoService],
})
export class PlatoModule {}
"""

update_file('d:/Proyecto_Diplomado/Backend/src/modules/menu/menu.service.ts', menu_service_content)
update_file('d:/Proyecto_Diplomado/Backend/src/modules/menu/dto/crear-menu.dto.ts', crear_menu_dto_content)
update_file('d:/Proyecto_Diplomado/Backend/src/modules/menu/menu.controller.ts', menu_controller_content)
update_file('d:/Proyecto_Diplomado/Backend/src/modules/plato/plato.controller.ts', plato_controller_content)
update_file('d:/Proyecto_Diplomado/Backend/src/modules/menu/menu.module.ts', menu_module_content)
update_file('d:/Proyecto_Diplomado/Backend/src/modules/plato/plato.module.ts', plato_module_content)
