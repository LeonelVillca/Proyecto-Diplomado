import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CrearDocumentoAdjuntoDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idSolicitud: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  tipo: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  url: string;
}