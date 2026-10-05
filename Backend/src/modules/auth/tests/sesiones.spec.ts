import { setup } from './auth-fixture';

describe('Sesiones revocables', () => {
  it('la renovación no reinicia la edad de sesión ni revive versiones revocadas', async () => {
    const { service, jwt, account } = setup();
    const started = Math.floor(Date.now() / 1000) - 5000;
    await service.renovarSesion({
      ...account.usuario,
      sessionStartedAt: started,
      sessionVersion: 0,
    });
    expect(jwt.sign).toHaveBeenCalledWith(
      expect.objectContaining({ sessionStartedAt: started, sv: 0 }),
    );
    await service.cerrarSesiones(1);
    await expect(
      service.renovarSesion({
        ...account.usuario,
        sessionStartedAt: started,
        sessionVersion: 0,
      }),
    ).rejects.toThrow();
  });
});
