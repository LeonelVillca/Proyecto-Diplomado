import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class CrearRolPermisoDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRol: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  idPermiso: number;
}