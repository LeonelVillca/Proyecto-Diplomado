import { Transform, Type } from 'class-transformer';
import {
  IsDefined,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
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

  @IsDefined({ message: 'La capacidad es obligatoria' })
  @Transform(({ value }) =>
    typeof value === 'string' && value.trim() !== '' ? Number(value) : value,
  )
  @IsInt({ message: 'La capacidad debe ser un número entero' })
  @Min(1, { message: 'La capacidad debe ser mayor que cero' })
  capacidad: number;

  @IsOptional()
  @IsIn(ESTADO_MESA)
  estado?: (typeof ESTADO_MESA)[number];
}
