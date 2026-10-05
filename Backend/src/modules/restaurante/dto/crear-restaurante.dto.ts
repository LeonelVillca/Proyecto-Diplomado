import { Type } from 'class-transformer';
import { DatosHorarioAtencionDto } from '../../horario-atencion/dto/datos-horario-atencion.dto';
import {
  IsBoolean,
  IsInt,
  IsNumber,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
  IsArray,
  ArrayUnique,
} from 'class-validator';

export class HorarioAtencionDto extends DatosHorarioAtencionDto {}

export class CrearRestauranteDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  idSolicitud?: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  nombre: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  tipoComida?: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true })
  tiposComidaIds?: number[];

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefono?: string;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  correo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  fotoPortada?: string;

  @IsOptional()
  @IsBoolean()
  estado?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  direccion?: string;

  @IsOptional()
  @IsNumber()
  latitud?: number;

  @IsOptional()
  @IsNumber()
  longitud?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => HorarioAtencionDto)
  horarios?: HorarioAtencionDto[];

  @IsOptional()
  @IsInt()
  @Min(1)
  mesasTotal?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  capacidadTotal?: number;
}
