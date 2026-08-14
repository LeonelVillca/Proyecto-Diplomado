import { IsString, MaxLength } from 'class-validator';

export class GoogleLoginDto {
  /// ID Token de Firebase emitido por Google Sign-In en el frontend.
  /// El backend lo verifica server-side con `firebase-admin`; nunca confía
  /// en correo/nombre/proveedor_id que vengan en el body.
  @IsString()
  @MaxLength(4096)
  idToken: string;
}
