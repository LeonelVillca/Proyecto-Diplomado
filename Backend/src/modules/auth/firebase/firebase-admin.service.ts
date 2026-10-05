import { Injectable, UnauthorizedException } from '@nestjs/common';
import { App } from 'firebase-admin/app';
import { FirebaseAppService } from './firebase-app.service';
import { DecodedIdToken, getAuth } from 'firebase-admin/auth';

// Datos verificados por Firebase para el ingreso con Google.
export interface UsuarioGoogleVerificado {
  uid: string;
  correo: string | undefined;
  emailVerificado: boolean;
  nombre: string | undefined;
  foto: string | null;
}

// Comprueba los tokens de Google recibidos del frontend.
@Injectable()
export class FirebaseAdminService {
  private readonly app: App | null;

  // Usa la aplicacion Firebase compartida.
  constructor(firebase: FirebaseAppService) {
    this.app = firebase.app;
  }

  // Verifica el token y devuelve la identidad de Google.
  async verificarIdToken(idToken: string): Promise<UsuarioGoogleVerificado> {
    if (!this.app) {
      throw new UnauthorizedException(
        'Autenticación con Google no configurada en el servidor',
      );
    }

    let decodedToken: DecodedIdToken;
    try {
      decodedToken = await getAuth(this.app).verifyIdToken(idToken, true);
    } catch {
      throw new UnauthorizedException('Token de Google inválido o expirado');
    }

    if (
      decodedToken.firebase?.sign_in_provider !== 'google.com' ||
      decodedToken.email_verified !== true
    ) {
      throw new UnauthorizedException(
        'Se requiere una cuenta de Google con correo verificado',
      );
    }
    return {
      uid: decodedToken.uid,
      correo:
        typeof decodedToken.email === 'string' ? decodedToken.email : undefined,
      emailVerificado: decodedToken.email_verified ?? false,
      nombre:
        typeof decodedToken.name === 'string' ? decodedToken.name : undefined,
      foto:
        typeof decodedToken.picture === 'string' ? decodedToken.picture : null,
    };
  }
}
