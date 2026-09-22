import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface CorreoTransaccional {
  destinatario: string;
  asunto: string;
  html: string;
  texto?: string;
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private configService: ConfigService) {}

  private async enviarCorreo(correo: CorreoTransaccional): Promise<void> {
    const apiKey = this.configService.get<string>('BREVO_API_KEY')?.trim();
    const remitente = this.configService.get<string>('MAIL_FROM')?.trim();
    if (!apiKey || !remitente) {
      this.logger.error('Falta configurar BREVO_API_KEY o MAIL_FROM.');
      throw new ServiceUnavailableException(
        'El servicio de correo no está configurado. Inténtalo más tarde.',
      );
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20_000);
    try {
      const response = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'api-key': apiKey,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          sender: {
            email: remitente,
            name:
              this.configService.get<string>('MAIL_FROM_NAME')?.trim() ||
              'Mesa Chapaca',
          },
          to: [{ email: correo.destinatario }],
          subject: correo.asunto,
          htmlContent: correo.html,
          ...(correo.texto ? { textContent: correo.texto } : {}),
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        this.logger.error(`Brevo rechazó el envío: HTTP ${response.status}.`);
        throw new ServiceUnavailableException(
          'Brevo no pudo aceptar el correo. Revisa la configuración del remitente e inténtalo más tarde.',
        );
      }
      this.logger.log('Correo transaccional aceptado por Brevo.');
    } catch (error) {
      if (error instanceof ServiceUnavailableException) throw error;
      const reason =
        error instanceof Error
          ? error.name === 'AbortError'
            ? 'timeout'
            : error.name
          : 'error desconocido';
      this.logger.error(`No se pudo conectar con la API de Brevo: ${reason}.`);
      throw new ServiceUnavailableException(
        'No se pudo conectar con el servicio de correo. Inténtalo más tarde.',
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  async enviarVerificacionSolicitud(correoDestino: string, token: string): Promise<void> {
    const apiBase = this.configService.get<string>('API_PUBLIC_URL') ?? 'http://localhost:3000';
    const url = new URL('/api/v1/solicitud/verificar-correo', apiBase);
    url.searchParams.set('token', token);
    await this.enviarCorreo({
      destinatario: correoDestino,
      asunto: 'Confirma tu solicitud - Mesa Chapaca',
      texto: `Confirma tu correo para que podamos revisar tu solicitud: ${url.toString()}\nEl enlace vence en 24 horas. Si no hiciste la solicitud, ignora este correo.`,
      html: `<p>Para que podamos revisar tu solicitud, confirma tu correo:</p><p><a href="${url.toString()}">Confirmar correo</a></p><p>El enlace vence en 24 horas. Si no hiciste la solicitud, ignora este correo.</p>`,
    });
  }

  async enviarInvitacion(correoDestino: string, token: string): Promise<void> {
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

    await this.enviarCorreo({
      destinatario: correoDestino,
      asunto: 'Invitación a Mesa Chapaca - Configura tu cuenta',
      html,
    });
  }

  async enviarRecuperacionPassword(correoDestino: string, pin: string): Promise<void> {
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

    await this.enviarCorreo({
      destinatario: correoDestino,
      asunto: 'Mesa Chapaca - Código de recuperación',
      html,
    });
  }
}
