import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';
import { ESTADO_MESA } from '../mesa.entity';

export class CrearMesaDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idRestaurante: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  numeroMesa: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  capacidad?: number;

  @IsOptional()
  @IsIn(ESTADO_MESA)
  estado?: (typeof ESTADO_MESA)[number];
}