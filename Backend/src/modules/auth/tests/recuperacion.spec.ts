import { setup } from './auth-fixture';

describe('Recuperacion de contrasena', () => {
  it('almacena el PIN cifrado con HMAC, limita intentos y no renueva el PIN durante un minuto', async () => {
    const { service, mail, getRecord } = setup();
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    const pin = mail.enviarRecuperacionPassword.mock.calls[0]?.[1];
    if (!pin) throw new Error('La prueba no recibió el PIN esperado');
    expect(getRecord().token).not.toBe(pin);
    expect(getRecord().token).toMatch(/^[a-f0-9]{64}$/);
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    expect(mail.enviarRecuperacionPassword).toHaveBeenCalledTimes(1);
    for (let i = 0; i < 5; i++)
      await expect(
        service.verificarPinRecuperacion({
          correo: 'u@example.test',
          pin: '000000',
        }),
      ).rejects.toThrow();
    expect(getRecord().intentosVerificacion).toBe(5);
    await expect(
      service.verificarPinRecuperacion({ correo: 'u@example.test', pin }),
    ).rejects.toThrow();
  });

  it('consume el PIN y revoca sesiones al cambiar la contraseña', async () => {
    const { service, mail, getRecord, account } = setup();
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    const pin = mail.enviarRecuperacionPassword.mock.calls[0]?.[1];
    if (!pin) throw new Error('La prueba no recibió el PIN esperado');
    await service.restablecerPassword({
      correo: 'u@example.test',
      pin,
      nuevaContrasena: 'New-test-password-123',
    });
    expect(getRecord().usado).toBe(true);
    expect(account.sessionVersion).toBe(1);
    await expect(
      service.restablecerPassword({
        correo: 'u@example.test',
        pin,
        nuevaContrasena: 'Other-pass-123',
      }),
    ).rejects.toThrow();
  });
});
