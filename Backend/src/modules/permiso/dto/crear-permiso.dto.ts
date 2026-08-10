import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CrearPermisoDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  codigo: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  descripcion?: string;
}
