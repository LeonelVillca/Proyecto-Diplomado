import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { CuentaAuth } from '../cuentas-auth/cuenta-auth.entity';
import { InvitacionToken } from '../invitacion-token/invitacion-token.entity';

describe('Autenticación y recuperación', () => {
  const secret = 'a'.repeat(64);
  function setup() {
    const user = { id: 1, estado: 'activo', correo: 'u@example.test' };
    const account: any = {
      id: 2,
      estado: true,
      usuario: user,
      sessionVersion: 0,
    };
    let record: any;
    const repo = {
      findOne: jest.fn(async (options: any) =>
        options.where.usado === false && record?.usado ? null : record,
      ),
      update: jest.fn(async () => {
        if (record) record.usado = true;
      }),
      create: (value: any) => ({
        ...value,
        id: 1,
        intentosVerificacion: 0,
        usado: false,
        fechaCreacion: new Date(),
      }),
      save: jest.fn(async (value) => {
        record = value;
        return value;
      }),
    };
    const accountRepo = {
      findOne: jest.fn(async () => account),
      create: jest.fn((value) => ({ ...value })),
      save: jest.fn(async (value) => {
        Object.assign(account, value);
        return value;
      }),
    };
    const manager = {
      query: jest.fn(async () => [{ id_token: 1 }]),
      save: jest.fn(async (value) => value),
      findOne: jest.fn(async (entity) =>
        entity === CuentaAuth ? account : record,
      ),
      getRepository: (entity) => {
        return entity === CuentaAuth ? accountRepo : repo;
      },
      update: jest.fn(async (_entity, _id, values) => {
        account.sessionVersion++;
        account.passwordHash = values.passwordHash;
      }),
    };
    const source = {
      transaction: async (fn) => fn(manager),
      getRepository: () => ({ find: async () => [] }),
    };
    const users = {
      buscarPorCorreo: async () => user,
      actualizar: jest.fn(),
      crear: jest.fn(),
    };
    const accounts = {
      buscarPorUsuario: async () => account,
      revocarSesiones: jest.fn(async () => {
        account.sessionVersion++;
      }),
    };
    const google = {
      verificarIdToken: jest.fn(
        async (): Promise<{
          correo: string;
          emailVerificado: boolean;
          uid: string;
        }> => ({
          correo: user.correo,
          emailVerificado: true,
          uid: 'uid',
        }),
      ),
    };
    const mail = {
      enviarRecuperacionPassword: jest.fn<
        Promise<void>,
        [correo: string, pin: string]
      >(),
    };
    mail.enviarRecuperacionPassword.mockResolvedValue(undefined);
    const jwt = { sign: jest.fn(() => 'token') };
    const service = new AuthService(
      users as any,
      accounts as any,
      {} as any,
      google as any,
      jwt as any,
      source as any,
      mail as any,
      new ConfigService({ JWT_SECRET: secret }),
    );
    return {
      service,
      account,
      users,
      google,
      jwt,
      mail,
      manager,
      getRecord: () => record,
      setRecord: (value: any) => {
        record = value;
      },
    };
  }
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
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
