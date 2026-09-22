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

  async enviarVerificacionSolicitud(correoDestino: string, token: string): Promise<void> {
    const apiBase = this.configService.get<string>('API_PUBLIC_URL') ?? 'http://localhost:3000';
    const url = new URL('/api/v1/solicitud/verificar-correo', apiBase);
    url.searchParams.set('token', token);
    await this.transporter.sendMail({
      from: this.configService.get<string>('MAIL_FROM'),
      to: correoDestino,
      subject: 'Confirma tu solicitud - Mesa Chapaca',
      text: `Confirma tu correo para que podamos revisar tu solicitud: ${url.toString()}\nEl enlace vence en 24 horas. Si no hiciste la solicitud, ignora este correo.`,
      html: `<p>Para que podamos revisar tu solicitud, confirma tu correo:</p><p><a href="${url.toString()}">Confirmar correo</a></p><p>El enlace vence en 24 horas. Si no hiciste la solicitud, ignora este correo.</p>`,
    });
  }

  async enviarInvitacion(correoDestino: string, token: string): Promise<void> {
    const from = this.configService.get<string>('MAIL_FROM');
    // Para entornos locales usamos el puerto por defecto de Flutter Web, en producción sería el dominio real
    const frontend = this.configService.get<string>('FRONTEND_URL') ?? 'http://localhost:62532';
    const url = `${new URL(frontend).origin}/#/crear-contrasena?token=${encodeURIComponent(token)}`;

    const html = `
      <div style="background-color: #F5EEE0; padding: 40px 20px; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(36, 21, 18, 0.05);">
          <!-- Encabezado dorado -->
          <div style="height: 6px; background-color: #D4AF37; width: 100%;"></div>
          
          <div style="padding: 40px;">
            <h1 style="color: #6B1233; margin-top: 0; font-size: 26px; font-weight: 700; text-align: center;">¡Bienvenido a Mesa Chapaca!</h1>
            
            <p style="color: #241512; font-size: 16px; line-height: 1.6; margin-top: 30px;">Hola,</p>
            <p style="color: #7A6A5C; font-size: 16px; line-height: 1.6;">Tu solicitud para administrar tu restaurante ha sido aprobada con éxito. Estamos encantados de tenerte en nuestra plataforma.</p>
            <p style="color: #7A6A5C; font-size: 16px; line-height: 1.6;">Para comenzar a gestionar tus reservas y tu perfil, por favor configura tu contraseña haciendo clic en el siguiente botón:</p>
            
            <div style="text-align: center; margin: 40px 0;">
              <a href="${url}" style="display: inline-block; background-color: #6B1233; color: #FFFFFF; padding: 14px 32px; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: bold; box-shadow: 0 4px 10px rgba(107, 18, 51, 0.3);">Configurar mi cuenta</a>
            </div>
            
            <p style="font-size: 13px; color: #8C7A6B; text-align: center; margin-top: 40px;">Este enlace es válido de forma temporal. Si expira, deberás solicitar uno nuevo desde el panel.</p>
          </div>
          
          <div style="background-color: #FFFCF6; padding: 20px; text-align: center; border-top: 1px solid #EAE0C9;">
            <p style="color: #8C7A6B; font-size: 13px; margin: 0;">&copy; ${new Date().getFullYear()} Mesa Chapaca. Todos los derechos reservados.</p>
          </div>
        </div>
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
      const details = error as { message?: string; code?: string; responseCode?: number; command?: string };
      this.logger.error(
        `Error al enviar invitación: code=${details.code ?? 'unknown'} responseCode=${details.responseCode ?? 'unknown'} command=${details.command ?? 'unknown'} message=${details.message ?? String(error)}`,
      );
      throw error;
    }
  }

  async enviarRecuperacionPassword(correoDestino: string, pin: string): Promise<void> {
    const from = this.configService.get<string>('MAIL_FROM');
    const html = `
      <div style="background-color: #F5EEE0; padding: 40px 20px; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(36, 21, 18, 0.05);">
          <!-- Encabezado dorado -->
          <div style="height: 6px; background-color: #B0832B; width: 100%;"></div>
          
          <div style="padding: 40px;">
            <h1 style="color: #241512; margin-top: 0; font-size: 24px; font-weight: 700; text-align: center;">Recuperación de Contraseña</h1>
            
            <p style="color: #7A6A5C; font-size: 16px; line-height: 1.6; text-align: center; margin-top: 30px;">
              Has solicitado restablecer tu contraseña para acceder al panel de administración de <strong>Mesa Chapaca</strong>.
            </p>
            <p style="color: #7A6A5C; font-size: 16px; line-height: 1.6; text-align: center;">
              Por favor, utiliza el siguiente código de seguridad para continuar:
            </p>
            
            <div style="text-align: center; margin: 40px 0;">
              <div style="display: inline-block; background-color: #FFFCF6; padding: 20px 40px; border: 2px dashed #D4AF37; border-radius: 12px;">
                <span style="color: #6B1233; font-size: 32px; letter-spacing: 8px; font-weight: 800; display: block; margin-left: 8px;">${pin}</span>
              </div>
            </div>
            
            <p style="font-size: 14px; color: #7A6A5C; text-align: center;">
              Este código es válido por <strong>15 minutos</strong>.
            </p>
            <p style="font-size: 13px; color: #8C7A6B; text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #F0F0F0;">
              Si no solicitaste este cambio, puedes ignorar este correo de forma segura. Tu cuenta está protegida.
            </p>
          </div>
          
          <div style="background-color: #FFFCF6; padding: 20px; text-align: center; border-top: 1px solid #EAE0C9;">
            <p style="color: #8C7A6B; font-size: 13px; margin: 0;">Mesa Chapaca &bull; Soporte Técnico</p>
          </div>
        </div>
      </div>
    `;

    try {
      await this.transporter.sendMail({
        from,
        to: correoDestino,
        subject: 'Mesa Chapaca - Código de recuperación',
        html,
      });
      this.logger.log(`Correo de recuperación enviado exitosamente a ${correoDestino}`);
    } catch (error) {
      const details = error as { message?: string; code?: string; responseCode?: number; command?: string };
      this.logger.error(
        `Error al enviar recuperación: code=${details.code ?? 'unknown'} responseCode=${details.responseCode ?? 'unknown'} command=${details.command ?? 'unknown'} message=${details.message ?? String(error)}`,
      );
      throw error;
    }
  }
}
