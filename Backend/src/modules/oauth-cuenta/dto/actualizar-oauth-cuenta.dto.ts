import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class ActualizarOauthCuentaDto {
  @IsOptional()
  @IsString()
  @MaxLength(30)
  proveedor?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  proveedorId?: string;

  @IsOptional()
  @IsBoolean()
  emailVerificado?: boolean;
}