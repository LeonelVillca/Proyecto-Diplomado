import { Injectable } from '@nestjs/common';
import { Restaurante } from './restaurante.entity';
import { TipoComida } from './tipo-comida.entity';
import { CrearRestauranteDto } from './dto/crear-restaurante.dto';
import { ActualizarRestauranteDto } from './dto/actualizar-restaurante.dto';
import { PerfilRestauranteService } from './services/perfil-restaurante.service';
import {
  RestauranteConsultasService,
  RestaurantePublicoRespuesta,
} from './queries/restaurante-consultas.service';

// Contrato estable para el controlador; cada operación delega al responsable del dominio.
@Injectable()
export class RestauranteService {
  // Recibe los servicios y repositorios que necesita esta clase.
  constructor(
    private readonly perfil: PerfilRestauranteService,
    private readonly consultas: RestauranteConsultasService,
  ) {}

  // Crea el perfil de un restaurante.
  crear(dto: CrearRestauranteDto): Promise<Restaurante> {
    return this.perfil.crear(dto);
  }

  // Lista los restaurantes.
  listarTodos(): Promise<any[]> {
    return this.consultas.listarTodos();
  }

  // Lista restaurantes para la administración del sistema.
  listarParaAdministrador(): Promise<any[]> {
    return this.consultas.listarParaAdministrador();
  }

  // Cambia el estado de un restaurante desde administración.
  cambiarEstadoComoAdministrador(id: number, estado: boolean): Promise<any> {
    return this.perfil.cambiarEstadoComoAdministrador(id, estado);
  }

  // Obtiene el ranking de restaurantes.
  obtenerRanking(limite = 10): Promise<any[]> {
    return this.consultas.obtenerRanking(limite);
  }

  // Lista los restaurantes de un usuario.
  listarPorUsuario(idUsuario: number): Promise<any[]> {
    return this.perfil.listarPorUsuario(idUsuario);
  }

  // Busca un restaurante por su identificador.
  buscarPorId(id: number): Promise<Restaurante> {
    return this.consultas.buscarPorId(id);
  }

  // Busca un restaurante visible para el público.
  buscarPorIdPublico(id: number): Promise<RestaurantePublicoRespuesta> {
    return this.consultas.buscarPorIdPublico(id);
  }

  // Lista los tipos de comida disponibles.
  listarTiposComida(): Promise<TipoComida[]> {
    return this.consultas.listarTiposComida();
  }

  // Actualiza un restaurante.
  actualizar(id: number, dto: ActualizarRestauranteDto): Promise<Restaurante> {
    return this.perfil.actualizar(id, dto);
  }

  // Elimina un restaurante.
  eliminar(id: number): Promise<void> {
    return this.perfil.eliminar(id);
  }

  // Sube la imagen de portada del restaurante.
  subirPortada(id: number, file: Express.Multer.File): Promise<Restaurante> {
    return this.perfil.subirPortada(id, file);
  }

  // Sube el logotipo del restaurante.
  subirLogo(id: number, file: Express.Multer.File): Promise<Restaurante> {
    return this.perfil.subirLogo(id, file);
  }

  // Sube imágenes a la galería del restaurante.
  subirGaleria(id: number, files: Express.Multer.File[]): Promise<Restaurante> {
    return this.perfil.subirGaleria(id, files);
  }
}
