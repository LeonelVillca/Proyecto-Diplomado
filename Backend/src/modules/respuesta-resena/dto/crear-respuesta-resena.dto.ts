import { IsInt, IsString, MinLength } from 'class-validator';

export class CrearRespuestaResenaDto {
  @IsInt()
  idResena: number;

  @IsInt()
  idUsuarioRestaurante: number;

  @IsString()
  @MinLength(1)
  texto: string;
}
