import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CrearOauthCuentaDto {
  @IsInt()
  @Min(1)
  idUsuario: number;

  @IsString()
  @MaxLength(30)
  proveedor: string;

  @IsString()
  @MaxLength(255)
  proveedorId: string;

  @IsOptional()
  @IsBoolean()
  emailVerificado?: boolean;
}