import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail()
  @MaxLength(150)
  correo: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}