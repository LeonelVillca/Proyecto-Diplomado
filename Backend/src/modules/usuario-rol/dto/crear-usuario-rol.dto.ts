import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class CrearUsuarioRolDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idUsuario: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRol: number;
}
