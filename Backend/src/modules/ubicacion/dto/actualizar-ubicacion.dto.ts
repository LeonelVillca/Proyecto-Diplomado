import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearUbicacionDto } from './crear-ubicacion.dto';

export class ActualizarUbicacionDto extends OmitType(PartialType(CrearUbicacionDto), [
  'idRestaurante',
]) {}