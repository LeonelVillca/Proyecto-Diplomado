import { IsString, MaxLength } from 'class-validator';

export class GoogleLoginDto {
  // Token de Google que el backend verifica con Firebase.
  @IsString()
  @MaxLength(4096)
  idToken: string;
}
