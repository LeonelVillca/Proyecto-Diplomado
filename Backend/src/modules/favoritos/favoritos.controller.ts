import { Controller, Post, Delete, Get, Param, ParseIntPipe, UseGuards } from '@nestjs/common';
import { FavoritosService } from './favoritos.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';

@Controller('favoritos')
export class FavoritosController {
  constructor(private readonly favoritosService: FavoritosService) {}

  @UseGuards(JwtAuthGuard)
  @Post('usuario/:idUsuario/restaurante/:idRestaurante')
  async addFavorito(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ) {
    return this.favoritosService.addFavorito(idUsuario, idRestaurante);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('usuario/:idUsuario/restaurante/:idRestaurante')
  async removeFavorito(
    @Param('idUsuario', ParseIntPipe) idUsuario: number,
    @Param('idRestaurante', ParseIntPipe) idRestaurante: number,
  ) {
    await this.favoritosService.removeFavorito(idUsuario, idRestaurante);
    return { message: 'Favorito eliminado' };
  }

  @UseGuards(JwtAuthGuard)
  @Get('usuario/:idUsuario')
  async getFavoritosPorUsuario(@Param('idUsuario', ParseIntPipe) idUsuario: number) {
    return this.favoritosService.getFavoritosPorUsuario(idUsuario);
  }
}
