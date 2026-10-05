import { Global, Module } from '@nestjs/common';
import { UsuarioRestauranteAccesoService } from './usuario-restaurante-acceso.service';

@Global()
@Module({
  providers: [UsuarioRestauranteAccesoService],
  exports: [UsuarioRestauranteAccesoService],
})
export class UsuarioRestauranteModule {}
