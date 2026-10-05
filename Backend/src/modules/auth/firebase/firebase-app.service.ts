import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, getApp, getApps, initializeApp } from 'firebase-admin/app';

@Injectable()
export class FirebaseAppService {
  private readonly logger = new Logger(FirebaseAppService.name);
  readonly app: App | null;

  // Inicializa o reutiliza la aplicacion Firebase.
  constructor(config: ConfigService) {
    const projectId = config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = config.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = config.get<string>('FIREBASE_PRIVATE_KEY');
    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn(
        'Firebase Admin no configurado; Google y push requieren credenciales.',
      );
      this.app = null;
      return;
    }
    this.app = getApps().length
      ? getApp()
      : initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey: privateKey.replace(/\\n/g, '\n'),
          }),
        });
  }
}
