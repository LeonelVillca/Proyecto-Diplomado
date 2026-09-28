import { IsIn, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RegistrarDispositivoDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  token: string;

  @IsIn(['android', 'ios'])
  plataforma: 'android' | 'ios';
}

export class DesregistrarDispositivoDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  token: string;
}
