import { setup } from './auth-fixture';

describe('Acceso con Google', () => {
  it('no permite login Google a una cuenta suspendida ni modifica el perfil', async () => {
    const { service, account, users, jwt } = setup();
    account.estado = false;
    await expect(
      service.loginGoogle({ idToken: 'google-token' }),
    ).rejects.toThrow();
    expect(users.actualizar).not.toHaveBeenCalled();
    expect(jwt.sign).not.toHaveBeenCalled();
  });

  it('no vincula Google con correo no verificado', async () => {
    const { service, google, users } = setup();
    google.verificarIdToken.mockResolvedValue({
      correo: 'u@example.test',
      emailVerificado: false,
      uid: 'uid',
    });
    await expect(service.loginGoogle({ idToken: 'token' })).rejects.toThrow();
    expect(users.actualizar).not.toHaveBeenCalled();
  });
});
