import { IsNotEmpty, IsString, MinLength, Matches } from 'class-validator';

export class CrearContrasenaDto {
  @IsString()
  @IsNotEmpty()
  token: string;

  // VUL-006: Contraseña con validación de complejidad igual que RestablecerPasswordDto
  @IsString()
  @IsNotEmpty()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, {
    message: 'La contraseña debe contener al menos una letra mayúscula, una minúscula, y un número o símbolo',
  })
  password: string;
}
