import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, getApp, getApps, initializeApp } from 'firebase-admin/app';
import { DecodedIdToken, getAuth } from 'firebase-admin/auth';

/// Perfil del usuario ya verificado por Firebase, extraído del ID Token.
export interface UsuarioGoogleVerificado {
  uid: string;
  correo: string | undefined;
  emailVerificado: boolean;
  nombre: string | undefined;
  foto: string | null;
}

/// Cliente de Firebase Admin para verificar los ID Tokens que manda el
/// frontend después de autenticar con Google. Es la única fuente confiable
/// de identidad: el backend nunca confía en datos que vengan en el body del
/// request sin haberlos validado contra Firebase.
@Injectable()
export class FirebaseAdminService {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private readonly app: App | null;

  constructor(configService: ConfigService) {
    const projectId = configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = configService.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = configService.get<string>('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn(
        'Firebase Admin no configurado (faltan FIREBASE_PROJECT_ID, ' +
          'FIREBASE_CLIENT_EMAIL o FIREBASE_PRIVATE_KEY). ' +
          'POST /auth/google responderá 401 hasta configurar las credenciales.',
      );
      this.app = null;
      return;
    }

    if (getApps().length === 0) {
      this.app = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      this.app = getApp();
    }
  }

  /// Verifica el ID Token de Firebase. Lanza `UnauthorizedException` si el
  /// token es inválido, está expirado o fue manipulado.
  async verificarIdToken(idToken: string): Promise<UsuarioGoogleVerificado> {
    if (!this.app) {
      throw new UnauthorizedException(
        'Autenticación con Google no configurada en el servidor',
      );
    }

    let decodedToken: DecodedIdToken;
    try {
      decodedToken = await getAuth(this.app).verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Token de Google inválido o expirado');
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
