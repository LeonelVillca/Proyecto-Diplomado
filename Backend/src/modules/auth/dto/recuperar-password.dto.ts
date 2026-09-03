import { IsEmail, IsNotEmpty, IsString, MinLength, Matches } from 'class-validator';

export class SolicitarRecuperacionDto {
  @IsEmail({}, { message: 'El correo debe ser un email válido' })
  @IsNotEmpty({ message: 'El correo es obligatorio' })
  correo: string;
}

export class VerificarPinDto {
  @IsEmail({}, { message: 'El correo debe ser un email válido' })
  @IsNotEmpty({ message: 'El correo es obligatorio' })
  correo: string;

  @IsString({ message: 'El PIN debe ser un texto' })
  @IsNotEmpty({ message: 'El PIN es obligatorio' })
  pin: string;
}

export class RestablecerPasswordDto {
  @IsEmail({}, { message: 'El correo debe ser un email válido' })
  @IsNotEmpty({ message: 'El correo es obligatorio' })
  correo: string;

  @IsString({ message: 'El PIN debe ser un texto' })
  @IsNotEmpty({ message: 'El PIN es obligatorio' })
  pin: string;

  @IsString()
  @IsNotEmpty({ message: 'La nueva contraseña es obligatoria' })
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, { 
    message: 'La contraseña debe contener al menos una letra mayúscula, una letra minúscula, y un número o símbolo' 
  })
  nuevaContrasena: string;
}
