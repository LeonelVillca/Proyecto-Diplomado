import { setup } from './auth-fixture';
import { InvitacionToken } from '../../invitacion-token/invitacion-token.entity';

describe('Contrasenas e invitaciones', () => {
  it('crea contraseña bloqueando el token sin FOR UPDATE sobre el join del usuario', async () => {
    const { service, manager, setRecord, account } = setup();
    const invitation = {
      id: 9,
      token: 'token-hash',
      tipo: 'invitacion',
      usado: false,
      fechaExpiracion: new Date(Date.now() + 60_000),
      usuario: account.usuario,
    };
    setRecord(invitation);

    await expect(
      service.crearContrasena({
        token: 'plaintext-invitation-token',
        password: 'Valid-password-123',
      }),
    ).resolves.toEqual({ mensaje: 'Contraseña creada exitosamente' });

    expect(manager.query.mock.calls[0][0]).toContain('SELECT id_token');
    expect(manager.query.mock.calls[0][0]).toContain('FOR UPDATE');
    expect(manager.query.mock.calls[0][1][1]).toBe('invitacion');
    expect(manager.query.mock.calls[0][1][0]).not.toBe(
      'plaintext-invitation-token',
    );
    expect(manager.findOne.mock.calls[0][0]).toBe(InvitacionToken);
    expect(manager.findOne.mock.calls[0][1]).not.toHaveProperty('lock');
    expect(invitation.usado).toBe(true);
    expect(account.passwordHash).toBeTruthy();
  });
});
