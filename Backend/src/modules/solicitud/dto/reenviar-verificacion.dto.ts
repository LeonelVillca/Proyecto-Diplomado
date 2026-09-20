import { IsEmail, MaxLength } from 'class-validator';

export class ReenviarVerificacionDto {
  @IsEmail()
  @MaxLength(150)
  correo: string;
}
