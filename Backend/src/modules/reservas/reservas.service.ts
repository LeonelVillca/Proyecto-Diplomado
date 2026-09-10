import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Reserva } from './reserva.entity';
import { CrearReservaDto } from './dto/crear-reserva.dto';
import { ActualizarReservaDto } from './dto/actualizar-reserva.dto';
import { Usuario } from '../usuarios/usuario.entity';
import { Mesa } from '../mesa/mesa.entity';
import { ReservasGateway } from './reservas.gateway';

@Injectable()
export class ReservasService {
  constructor(
    @InjectRepository(Reserva)
    private readonly reservasRepo: Repository<Reserva>,
    @InjectRepository(Usuario)
    private readonly usuariosRepo: Repository<Usuario>,
    @InjectRepository(Mesa)
    private readonly mesasRepo: Repository<Mesa>,
    private readonly reservasGateway: ReservasGateway,
  ) {}

  async crear(dto: CrearReservaDto): Promise<Reserva> {
    const usuario = await this.usuariosRepo.findOne({ where: { id: dto.idUsuario } });
    if (!usuario) throw new NotFoundException('Usuario no encontrado');

    const mesa = await this.mesasRepo.findOne({ 
      where: { id: dto.idMesa },
      relations: { restaurante: true } 
    });
    if (!mesa) throw new NotFoundException('Mesa no encontrada');

    const reservaExistente = await this.reservasRepo.findOne({
      where: {
        mesa: { id: dto.idMesa },
        fecha: dto.fecha,
        hora: dto.hora,
        estado: In(['pendiente', 'aprobada', 'confirmada']),
      },
    });

    if (reservaExistente) {
      throw new BadRequestException('La mesa no está disponible en la fecha y hora seleccionadas');
    }

    const reserva = this.reservasRepo.create({
      ...dto,
      usuario,
      mesa,
      estado: 'pendiente',
    });

    const guardada = await this.reservasRepo.save(reserva);
    
    // Attach idRestaurante for the WebSocket event
    const payload = {
      ...guardada,
      idRestaurante: mesa.restaurante.id
    };
    this.reservasGateway.emitNuevaReserva(payload);
    
    return guardada;
  }

  listarTodas(): Promise<Reserva[]> {
    return this.reservasRepo.find({ relations: { usuario: true, mesa: { restaurante: true } } });
  }

  async buscarPorId(id: number): Promise<Reserva> {
    const reserva = await this.reservasRepo.findOne({
      where: { id },
      relations: { usuario: true, mesa: { restaurante: true } },
    });
    if (!reserva) throw new NotFoundException(`Reserva #${id} no encontrada`);
    return reserva;
  }
  
  async listarPorUsuario(idUsuario: number): Promise<Reserva[]> {
    return this.reservasRepo.find({
      where: { usuario: { id: idUsuario } },
      relations: { mesa: { restaurante: true } }
    });
  }
  
  async listarPorRestaurante(idRestaurante: number): Promise<Reserva[]> {
    return this.reservasRepo.find({
      where: { mesa: { restaurante: { id: idRestaurante } } },
      relations: { usuario: true, mesa: true }
    });
  }

  async actualizar(id: number, dto: ActualizarReservaDto): Promise<Reserva> {
    const reserva = await this.buscarPorId(id);

    if (dto.idMesa) {
      const mesa = await this.mesasRepo.findOne({ where: { id: dto.idMesa } });
      if (!mesa) throw new NotFoundException('Mesa no encontrada');
      reserva.mesa = mesa;
    }

    if (dto.estado && dto.estado !== reserva.estado) {
        reserva.estado = dto.estado;
        
        // Emite evento con idRestaurante
        this.reservasGateway.emitActualizacionReserva(
          reserva.id, 
          reserva.estado, 
          reserva.mesa.restaurante.id
        );
    }
    
    if (dto.fecha) reserva.fecha = dto.fecha;
    if (dto.hora) reserva.hora = dto.hora;
    if (dto.numeroPersonas) reserva.numeroPersonas = dto.numeroPersonas;
    if (dto.comentarios !== undefined) reserva.comentarios = dto.comentarios;

    return this.reservasRepo.save(reserva);
  }

  async eliminar(id: number): Promise<void> {
    const reserva = await this.buscarPorId(id);
    await this.reservasRepo.remove(reserva);
  }
}
