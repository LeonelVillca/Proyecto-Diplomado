import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurante } from './restaurante.entity';
import { RestauranteService } from './restaurante.service';
import { RestauranteController } from './restaurante.controller';
import { Solicitud } from '../solicitud/solicitud.entity';
import { Ubicacion } from '../ubicacion/ubicacion.entity';
import { HorarioAtencion } from '../horario-atencion/horario-atencion.entity';
import { HorarioAtencionModule } from '../horario-atencion/horario-atencion.module';
import { Mesa } from '../mesa/mesa.entity';
import { Imagen } from '../imagen/imagen.entity';
import { Resena } from '../resenas/resena.entity';
import { StorageModule } from '../../core/storage/storage.module';
import { UsuarioRestaurante } from '../usuario-restaurante/usuario-restaurante.entity';
import { TipoComida } from './tipo-comida.entity';
import { PublicacionRestauranteService } from './services/publicacion-restaurante.service';
import { PerfilRestauranteService } from './services/perfil-restaurante.service';
import { RestauranteConsultasService } from './queries/restaurante-consultas.service';

@Module({
  imports: [
    StorageModule,
    HorarioAtencionModule,
    TypeOrmModule.forFeature([
      Restaurante,
      Solicitud,
      Ubicacion,
      HorarioAtencion,
      Mesa,
      Imagen,
      Resena,
      UsuarioRestaurante,
      TipoComida,
    ]),
  ],
  controllers: [RestauranteController],
  providers: [
    RestauranteService,
    PerfilRestauranteService,
    RestauranteConsultasService,
    PublicacionRestauranteService,
  ],
  exports: [RestauranteService],
})
export class RestauranteModule {}
