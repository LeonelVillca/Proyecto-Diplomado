import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Resena } from './resena.entity';
import { CrearResenaDto } from './dto/crear-resena.dto';
import { ActualizarResenaDto } from './dto/actualizar-resena.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Restaurante } from '../restaurante/restaurante.entity';

@Injectable()
export class ResenasService {
  constructor(
    @InjectRepository(Resena)
    private readonly resenasRepo: Repository<Resena>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
    @InjectRepository(Restaurante)
    private readonly restaurantesRepo: Repository<Restaurante>,
  ) {}

  async crear(dto: CrearResenaDto): Promise<Resena> {
    const usuario = await this.usuariosRepo.findOne({ where: { id: dto.idUsuario } });
    if (!usuario) throw new NotFoundException('Usuario no encontrado');

    const restaurante = await this.restaurantesRepo.findOne({ where: { id: dto.idRestaurante } });
    if (!restaurante) throw new NotFoundException('Restaurante no encontrado');

    const resena = this.resenasRepo.create({
      ...dto,
      usuario,
      restaurante,
    });

    return this.resenasRepo.save(resena);
  }

  listarTodas(): Promise<Resena[]> {
    return this.resenasRepo.find({ relations: { usuario: true, restaurante: true } });
  }

  async buscarPorId(id: number): Promise<Resena> {
    const resena = await this.resenasRepo.findOne({
      where: { id },
      relations: { usuario: true, restaurante: true },
    });
    if (!resena) throw new NotFoundException(`Resena #${id} no encontrada`);
    return resena;
  }
  
  async listarPorRestaurante(idRestaurante: number): Promise<Resena[]> {
    return this.resenasRepo.find({
      where: { restaurante: { id: idRestaurante } },
      relations: { usuario: true },
      order: { fecha: 'DESC' }
    });
  }

  async actualizar(id: number, dto: ActualizarResenaDto): Promise<Resena> {
    const resena = await this.buscarPorId(id);

    if (dto.comentario !== undefined) resena.comentario = dto.comentario;
    if (dto.calificacion !== undefined) resena.calificacion = dto.calificacion;

    return this.resenasRepo.save(resena);
  }

  async eliminar(id: number): Promise<void> {
    const resena = await this.buscarPorId(id);
    await this.resenasRepo.remove(resena);
  }
}
