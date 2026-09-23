import {
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Min,
  Max,
  MaxLength,
} from 'class-validator';

export class CrearReservaDto {
  @IsInt()
  idUsuario: number;

  @IsInt()
  idMesa: number;

  @IsDateString()
  fecha: string;

  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/, {
    message: 'La hora debe estar en formato HH:MM o HH:MM:SS',
  })
  hora: string;

  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(480)
  duracionMinutos?: number = 120;

  @IsInt()
  @Min(1)
  numeroPersonas: number;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  comentarios?: string;
}
