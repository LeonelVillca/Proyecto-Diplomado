import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CrearRespuestaResenaDto } from './crear-respuesta-resena.dto';

export class ActualizarRespuestaResenaDto extends PartialType(
  OmitType(CrearRespuestaResenaDto, ['idResena', 'idUsuarioRestaurante'] as const),
) {}
