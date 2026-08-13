import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CrearHorarioAtencionDto } from './crear-horario-atencion.dto';

export class ActualizarHorarioAtencionDto extends OmitType(
  PartialType(CrearHorarioAtencionDto),
  ['idRestaurante'],
) {}