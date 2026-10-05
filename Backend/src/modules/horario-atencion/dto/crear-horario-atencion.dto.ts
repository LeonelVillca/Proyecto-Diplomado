import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';
import { DatosHorarioAtencionDto } from './datos-horario-atencion.dto';

export { HORA_REGEX } from './datos-horario-atencion.dto';

export class CrearHorarioAtencionDto extends DatosHorarioAtencionDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;
}
