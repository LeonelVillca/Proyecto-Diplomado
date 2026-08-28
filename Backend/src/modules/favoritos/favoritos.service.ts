import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorito } from './favorito.entity';

@Injectable()
export class FavoritosService {
  constructor(
    @InjectRepository(Favorito)
    private readonly favoritoRepository: Repository<Favorito>,
  ) {}

  async addFavorito(idUsuario: number, idRestaurante: number): Promise<Favorito> {
    const existe = await this.favoritoRepository.findOne({
      where: { usuario: { id: idUsuario }, restaurante: { id: idRestaurante } },
    });
    if (existe) {
      return existe;
    }
    const nuevo = this.favoritoRepository.create({
      usuario: { id: idUsuario },
      restaurante: { id: idRestaurante },
    });
    return this.favoritoRepository.save(nuevo);
  }

  async removeFavorito(idUsuario: number, idRestaurante: number): Promise<void> {
    await this.favoritoRepository.delete({
      usuario: { id: idUsuario },
      restaurante: { id: idRestaurante },
    });
  }

  async getFavoritosPorUsuario(idUsuario: number): Promise<Favorito[]> {
    return this.favoritoRepository.find({
      where: { usuario: { id: idUsuario } },
      relations: { restaurante: true },
    });
  }
}
