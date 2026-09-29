import { IsDateString, IsIn, IsString, Matches } from 'class-validator';

export class ActualizarEstadoHorarioDto {
  @IsDateString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  fecha: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  hora: string;

  @IsIn(['libre', 'ocupada', 'reservada'])
  estado: 'libre' | 'ocupada' | 'reservada';
}
