import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RespuestaResena } from './respuesta-resena.entity';
import { CrearRespuestaResenaDto } from './dto/crear-respuesta-resena.dto';
import { ActualizarRespuestaResenaDto } from './dto/actualizar-respuesta-resena.dto';
import { Resena } from '../resenas/resena.entity';
import { Usuario } from '../usuarios/usuario.entity';

@Injectable()
export class RespuestaResenaService {
  constructor(
    @InjectRepository(RespuestaResena)
    private readonly respuestaRepo: Repository<RespuestaResena>,
    @InjectRepository(Resena)
    private readonly resenasRepo: Repository<Resena>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
  ) {}

  async crear(dto: CrearRespuestaResenaDto): Promise<RespuestaResena> {
    const resena = await this.resenasRepo.findOne({ where: { id: dto.idResena } });
    if (!resena) throw new NotFoundException('Reseña no encontrada');

    const usuarioRestaurante = await this.usuariosRepo.findOne({ where: { id: dto.idUsuarioRestaurante } });
    if (!usuarioRestaurante) throw new NotFoundException('Usuario no encontrado');

    const respuesta = this.respuestaRepo.create({
      ...dto,
      resena,
      usuarioRestaurante,
    });

    return this.respuestaRepo.save(respuesta);
  }

  listarTodas(): Promise<RespuestaResena[]> {
    return this.respuestaRepo.find({ relations: { resena: true, usuarioRestaurante: true } });
  }

  async buscarPorId(id: number): Promise<RespuestaResena> {
    const respuesta = await this.respuestaRepo.findOne({
      where: { id },
      relations: { resena: { restaurante: true }, usuarioRestaurante: true },
    });
    if (!respuesta) throw new NotFoundException(`Respuesta #${id} no encontrada`);
    return respuesta;
  }
  
  async listarPorResena(idResena: number): Promise<RespuestaResena[]> {
    return this.respuestaRepo.find({
      where: { resena: { id: idResena } },
      relations: { usuarioRestaurante: true },
      order: { fechaRespuesta: 'DESC' }
    });
  }

  async actualizar(id: number, dto: ActualizarRespuestaResenaDto): Promise<RespuestaResena> {
    const respuesta = await this.buscarPorId(id);

    if (dto.texto !== undefined) respuesta.texto = dto.texto;

    return this.respuestaRepo.save(respuesta);
  }

  async eliminar(id: number): Promise<void> {
    const respuesta = await this.buscarPorId(id);
    await this.respuestaRepo.remove(respuesta);
  }
}
