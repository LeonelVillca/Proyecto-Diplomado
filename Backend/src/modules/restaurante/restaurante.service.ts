import { Injectable } from '@nestjs/common';
import { Restaurante } from './restaurante.entity';
import { TipoComida } from './tipo-comida.entity';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { PerfilRestauranteService } from './services/perfil-restaurante.service';
import { RestauranteConsultasService } from './queries/restaurante-consultas.service';

// Contrato estable para el controlador; cada operación delega al responsable del dominio.
@Injectable()
export class RestauranteService {
  constructor(
    private readonly perfil: PerfilRestauranteService,
    private readonly consultas: RestauranteConsultasService,
  ) {}

  crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.perfil.crear(dto);
  }

  listarTodos(): Promise<any[]> {
    return this.consultas.listarTodos();
  }

  listarParaAdministrador(): Promise<any[]> {
    return this.consultas.listarParaAdministrador();
  }

  cambiarEstadoComoAdministrador(id: number, estado: boolean): Promise<any> {
    return this.perfil.cambiarEstadoComoAdministrador(id, estado);
  }

  obtenerRanking(limite = 10): Promise<any[]> {
    return this.consultas.obtenerRanking(limite);
  }

  listarPorUsuario(idUsuario: number): Promise<any[]> {
    return this.perfil.listarPorUsuario(idUsuario);
  }

  buscarPorId(id: number): Promise<Restaurante> {
    return this.consultas.buscarPorId(id);
  }

  buscarPorIdPublico(id: number): Promise<Restaurante> {
    return this.consultas.buscarPorIdPublico(id);
  }

  listarTiposComida(): Promise<TipoComida[]> {
    return this.consultas.listarTiposComida();
  }

  actualizar(id: number, dto: ActualizarRestauranteDto): Promise<Restaurante> {
    return this.perfil.actualizar(id, dto);
  }

  eliminar(id: number): Promise<void> {
    return this.perfil.eliminar(id);
  }

  subirPortada(id: number, file: Express.Multer.File): Promise<Restaurante> {
    return this.perfil.subirPortada(id, file);
  }

  subirLogo(id: number, file: Express.Multer.File): Promise<Restaurante> {
    return this.perfil.subirLogo(id, file);
  }

  subirGaleria(id: number, files: Express.Multer.File[]): Promise<Restaurante> {
    return this.perfil.subirGaleria(id, files);
  }
}
