import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CrearResenaDto } from './crear-resena.dto';

export class ActualizarResenaDto extends PartialType(
  OmitType(CrearResenaDto, ['idUsuario', 'idRestaurante'] as const),
) {}
