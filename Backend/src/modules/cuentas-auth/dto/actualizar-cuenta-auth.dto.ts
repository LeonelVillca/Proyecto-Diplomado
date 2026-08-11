import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class ActualizarCuentaAuthDto {
  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;

  @IsOptional()
  @IsBoolean()
  estado?: boolean;
}