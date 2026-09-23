import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CrearExcepcionHorarioDto } from './crear-excepcion-horario.dto';

export class ActualizarExcepcionHorarioDto extends PartialType(
  OmitType(CrearExcepcionHorarioDto, ['idRestaurante'] as const),
) {}
