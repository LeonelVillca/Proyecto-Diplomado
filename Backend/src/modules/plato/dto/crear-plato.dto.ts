import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';
import { DatosPlatoDto } from './datos-plato.dto';

export class CrearPlatoDto extends DatosPlatoDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idMenu: number;
}
