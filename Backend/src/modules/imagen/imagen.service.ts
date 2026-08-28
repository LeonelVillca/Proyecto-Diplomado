import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Imagen } from './imagen.entity';
import { CrearImagenDto } from './dto/crear-imagen.dto';
import { ActualizarImagenDto } from './dto/actualizar-imagen.dto';
import { Plato } from '../plato/plato.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class ImagenService {
  upload(file: Express.Multer.File, filename: string) {
    throw new Error('Method not implemented.');
  }
  constructor(
    @InjectRepository(Imagen)
    private readonly imagenRepository: Repository<Imagen>,
    @InjectRepository(Plato)
    private readonly platoRepository: Repository<Plato>,
    @InjectRepository(Restaurante)
    private readonly restauranteRepository: Repository<Restaurante>,
  ) {}

  private validarExclusividad(idPlato?: number, idRestaurante?: number): void {
    const tienePlato = idPlato !== undefined;
    const tieneRestaurante = idRestaurante !== undefined;
    if (tienePlato === tieneRestaurante) {
      throw new BadRequestException(
        'Una imagen debe pertenecer exactamente a un plato o a un restaurante, no a ambos ni a ninguno',
      );
    }
  }

  async crear(dto: CrearImagenDto): Promise<Imagen> {
    this.validarExclusividad(dto.idPlato, dto.idRestaurante);

    if (dto.idPlato !== undefined) {
      const plato = await this.platoRepository.findOneBy({ id: dto.idPlato });
      if (!plato) {
        throw new NotFoundException(`Plato con id ${dto.idPlato} no encontrado`);
      }
    }
    if (dto.idRestaurante !== undefined) {
      const restaurante = await this.restauranteRepository.findOneBy({
        id: dto.idRestaurante,
      });
      if (!restaurante) {
        throw new NotFoundException(
          `Restaurante con id ${dto.idRestaurante} no encontrado`,
        );
      }
    }

    const { idPlato, idRestaurante, ...datos } = dto;
    const imagen = this.imagenRepository.create({
      ...datos,
      plato: idPlato ? { id: idPlato } : null,
      restaurante: idRestaurante ? { id: idRestaurante } : null,
    });
    return this.imagenRepository.save(imagen);
  }

  listarTodos(): Promise<Imagen[]> {
    return this.imagenRepository.find({
      relations: { plato: true, restaurante: true },
    });
  }

  async buscarPorId(id: number): Promise<Imagen> {
    const imagen = await this.imagenRepository.findOne({
      where: { id },
      relations: { plato: true, restaurante: true },
    });
    if (!imagen) {
      throw new NotFoundException(`Imagen con id ${id} no encontrada`);
    }
    return imagen;
  }

  listarPorPlato(idPlato: number): Promise<Imagen[]> {
    return this.imagenRepository.find({
      where: { plato: { id: idPlato } },
      relations: { plato: true },
    });
  }

  listarPorRestaurante(idRestaurante: number): Promise<Imagen[]> {
    return this.imagenRepository.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { restaurante: true },
    });
  }

  async actualizar(id: number, dto: ActualizarImagenDto): Promise<Imagen> {
    const imagen = await this.buscarPorId(id);

    const idPlatoNuevo = dto.idPlato !== undefined ? dto.idPlato : imagen.plato?.id;
    const idRestNuevo =
      dto.idRestaurante !== undefined
        ? dto.idRestaurante
        : imagen.restaurante?.id;
    this.validarExclusividad(idPlatoNuevo, idRestNuevo);

    if (dto.idPlato !== undefined) {
      const plato = await this.platoRepository.findOneBy({ id: dto.idPlato });
      if (!plato) {
        throw new NotFoundException(`Plato con id ${dto.idPlato} no encontrado`);
      }
      imagen.plato = plato;
    }
    if (dto.idRestaurante !== undefined) {
      const restaurante = await this.restauranteRepository.findOneBy({
        id: dto.idRestaurante,
      });
      if (!restaurante) {
        throw new NotFoundException(
          `Restaurante con id ${dto.idRestaurante} no encontrado`,
        );
      }
      imagen.restaurante = restaurante;
    }

    const { idPlato: _p, idRestaurante: _r, ...datos } = dto;
    Object.assign(imagen, datos);
    return this.imagenRepository.save(imagen);
  }

  async eliminar(id: number): Promise<void> {
    const imagen = await this.buscarPorId(id);
    await this.imagenRepository.delete(imagen.id);
  }
}