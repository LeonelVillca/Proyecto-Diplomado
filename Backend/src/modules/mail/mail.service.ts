import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter: nodemailer.Transporter;
  private readonly logger = new Logger(MailService.name);

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('MAIL_HOST'),
      port: parseInt(this.configService.get<string>('MAIL_PORT') || '465', 10),
      secure: this.configService.get<string>('MAIL_SECURE') === 'true',
      auth: {
        user: this.configService.get<string>('MAIL_USER'),
        pass: this.configService.get<string>('MAIL_PASS'),
      },
    });
  }

  async enviarInvitacion(correoDestino: string, token: string): Promise<void> {
    const from = this.configService.get<string>('MAIL_FROM');
    // Para entornos locales usamos el puerto por defecto de Flutter Web, en producción sería el dominio real
    const url = `http://localhost:62532/#/crear-contrasena?token=${token}`; 

    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #6B1A35; text-align: center;">¡Bienvenido a Mesa Chapaca!</h2>
        <p>Hola,</p>
        <p>Tu solicitud para administrar tu restaurante en <strong>Mesa Chapaca</strong> ha sido aprobada.</p>
        <p>Por favor, haz clic en el siguiente botón para establecer tu contraseña y acceder al panel de administración:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${url}" style="background-color: #6B1A35; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Crear mi Contraseña</a>
        </div>
        <p style="font-size: 13px; color: #777;">Este enlace es válido por 48 horas. Si expira, deberás solicitar uno nuevo.</p>
        <p>Atentamente,<br>El equipo de Mesa Chapaca</p>
      </div>
    `;

    try {
      await this.transporter.sendMail({
        from,
        to: correoDestino,
        subject: 'Invitación a Mesa Chapaca - Configura tu cuenta',
        html,
      });
      this.logger.log(`Invitación enviada exitosamente a ${correoDestino}`);
    } catch (error) {
      this.logger.error(`Error al enviar invitación a ${correoDestino}:`, error);
      throw error;
    }
  }
}
