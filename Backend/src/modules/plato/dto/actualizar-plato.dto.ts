import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearPlatoDto } from './crear-plato.dto';

export class ActualizarPlatoDto extends OmitType(PartialType(CrearPlatoDto), [
  'idMenu',
]) {}