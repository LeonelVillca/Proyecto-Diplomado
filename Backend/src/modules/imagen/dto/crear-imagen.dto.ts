import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CrearImagenDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idPlato?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante?: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  url: string;
}