import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CrearCuentaAuthDto {
  @IsInt()
  @Min(1)
  idUsuario: number;

  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}