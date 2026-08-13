import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearMesaDto } from './crear-mesa.dto';

export class ActualizarMesaDto extends OmitType(PartialType(CrearMesaDto), [
  'idRestaurante',
]) {}