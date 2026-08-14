import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CrearResenaDto {
  @IsInt()
  idUsuario: number;

  @IsInt()
  idRestaurante: number;

  @IsOptional()
  @IsString()
  comentario?: string;

  @IsInt()
  @Min(1)
  @Max(5)
  calificacion: number;
}
