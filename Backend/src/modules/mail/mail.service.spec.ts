import { ConfigService } from '@nestjs/config';
import { MailService } from './mail.service';

describe('MailService con Brevo API', () => {
  const config = new ConfigService({
    BREVO_API_KEY: 'test-api-key',
    MAIL_FROM: 'sender@example.test',
    MAIL_FROM_NAME: 'Mesa Chapaca',
    API_PUBLIC_URL: 'https://api.example.test',
    FRONTEND_URL: 'https://app.example.test',
  });
  let service: MailService;
  let fetchMock: jest.SpyInstance;

  beforeEach(() => {
    service = new MailService(config);
    fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue({ ok: true, status: 201 } as Response);
  });

  afterEach(() => jest.restoreAllMocks());

  it('envía la verificación de solicitud por HTTPS con los datos del remitente', async () => {
    await service.enviarVerificacionSolicitud(
      'recipient@example.test',
      'verification-token',
    );

    expect(fetchMock).toHaveBeenCalledWith(
      'https://api.brevo.com/v3/smtp/email',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ 'api-key': 'test-api-key' }),
      }),
    );
    const payload = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(payload.sender).toEqual({
      email: 'sender@example.test',
      name: 'Mesa Chapaca',
    });
    expect(payload.to).toEqual([{ email: 'recipient@example.test' }]);
    expect(payload.htmlContent).toContain('verification-token');
  });

  it('envía invitaciones y recuperación usando sus asuntos y contenido', async () => {
    await service.enviarInvitacion('recipient@example.test', 'invite-token');
    await service.enviarRecuperacionPassword('recipient@example.test', '123456');

    const invitation = JSON.parse(fetchMock.mock.calls[0][1].body);
    const recovery = JSON.parse(fetchMock.mock.calls[1][1].body);
    expect(invitation.subject).toContain('Invitación');
    expect(invitation.htmlContent).toContain('invite-token');
    expect(recovery.subject).toContain('recuperación');
    expect(recovery.htmlContent).toContain('123456');
  });

  it('devuelve un error 503 claro cuando Brevo rechaza el envío', async () => {
    fetchMock.mockResolvedValue({ ok: false, status: 401 } as Response);

    await expect(
      service.enviarRecuperacionPassword('recipient@example.test', '123456'),
    ).rejects.toMatchObject({ status: 503 });
  });

  it('no hace peticiones si falta la clave de Brevo', async () => {
    service = new MailService(new ConfigService({ MAIL_FROM: 'sender@example.test' }));

    await expect(
      service.enviarRecuperacionPassword('recipient@example.test', '123456'),
    ).rejects.toMatchObject({ status: 503 });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
