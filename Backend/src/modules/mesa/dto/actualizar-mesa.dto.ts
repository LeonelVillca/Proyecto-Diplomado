import {
  IntersectionType,
  OmitType,
  PartialType,
  PickType,
} from '@nestjs/mapped-types';
import { CrearMesaDto } from './crear-mesa.dto';

export class ActualizarMesaDto extends IntersectionType(
  OmitType(PartialType(CrearMesaDto), ['idRestaurante', 'capacidad']),
  // Solo capacidad distingue entre omisión (permitida) y null (inválido).
  PartialType(PickType(CrearMesaDto, ['capacidad']), {
    skipNullProperties: false,
  }),
) {}
