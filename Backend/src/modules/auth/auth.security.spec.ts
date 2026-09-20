import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { CuentaAuth } from '../cuentas-auth/cuenta-auth.entity';
import { InvitacionToken } from '../invitacion-token/invitacion-token.entity';

describe('Autenticación y recuperación', () => {
  const secret = 'a'.repeat(64);
  function setup() {
    const user = { id: 1, estado: 'activo', correo: 'u@example.test' };
    const account: any = { id: 2, estado: true, usuario: user, sessionVersion: 0 };
    let record: any;
    const repo = {
      findOne: jest.fn(async (options: any) => options.where.usado === false && record?.usado ? null : record),
      update: jest.fn(async () => { if (record) record.usado = true; }),
      create: (value: any) => ({ ...value, id: 1, intentosVerificacion: 0, usado: false, fechaCreacion: new Date() }),
      save: jest.fn(async (value) => { record = value; return value; }),
    };
    const manager = {
      findOne: jest.fn(async (entity) => entity === CuentaAuth ? account : record),
      getRepository: (entity) => { expect(entity).toBe(InvitacionToken); return repo; },
      update: jest.fn(async (_entity, _id, values) => { account.sessionVersion++; account.passwordHash = values.passwordHash; }),
    };
    const source = { transaction: async (fn) => fn(manager), getRepository: () => ({ find: async () => [] }) };
    const users = { buscarPorCorreo: async () => user, actualizar: jest.fn(), crear: jest.fn() };
    const accounts = { buscarPorUsuario: async () => account, revocarSesiones: jest.fn(async () => { account.sessionVersion++; }) };
    const google = { verificarIdToken: jest.fn(async () => ({ correo: user.correo, emailVerificado: true, uid: 'uid' })) };
    const mail = { enviarRecuperacionPassword: jest.fn(async () => {}) };
    const jwt = { sign: jest.fn(() => 'token') };
    const service = new AuthService(users as any, accounts as any, {} as any, google as any, jwt as any, source as any, mail as any, new ConfigService({ JWT_SECRET: secret }));
    return { service, account, users, google, jwt, mail, manager, getRecord: () => record };
  }
  it('no permite login Google a una cuenta suspendida ni modifica el perfil', async () => {
    const { service, account, users, jwt } = setup();
    account.estado = false;
    await expect(service.loginGoogle({ idToken: 'google-token' })).rejects.toThrow();
    expect(users.actualizar).not.toHaveBeenCalled();
    expect(jwt.sign).not.toHaveBeenCalled();
  });
  it('no vincula Google con correo no verificado', async () => {
    const { service, google, users } = setup();
    google.verificarIdToken.mockResolvedValue({ correo: 'u@example.test', emailVerificado: false, uid: 'uid' });
    await expect(service.loginGoogle({ idToken: 'token' })).rejects.toThrow();
    expect(users.actualizar).not.toHaveBeenCalled();
  });
  it('almacena el PIN cifrado con HMAC, limita intentos y no renueva el PIN durante un minuto', async () => {
    const { service, mail, getRecord } = setup();
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    const pin = mail.enviarRecuperacionPassword.mock.calls[0][1];
    expect(getRecord().token).not.toBe(pin);
    expect(getRecord().token).toMatch(/^[a-f0-9]{64}$/);
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    expect(mail.enviarRecuperacionPassword).toHaveBeenCalledTimes(1);
    for (let i = 0; i < 5; i++) await expect(service.verificarPinRecuperacion({ correo: 'u@example.test', pin: '000000' })).rejects.toThrow();
    expect(getRecord().intentosVerificacion).toBe(5);
    await expect(service.verificarPinRecuperacion({ correo: 'u@example.test', pin })).rejects.toThrow();
  });
  it('consume el PIN y revoca sesiones al cambiar la contraseña', async () => {
    const { service, mail, getRecord, account } = setup();
    await service.solicitarRecuperacion({ correo: 'u@example.test' });
    const pin = mail.enviarRecuperacionPassword.mock.calls[0][1];
    await service.restablecerPassword({ correo: 'u@example.test', pin, nuevaContrasena: 'New-test-password-123' });
    expect(getRecord().usado).toBe(true);
    expect(account.sessionVersion).toBe(1);
    await expect(service.restablecerPassword({ correo: 'u@example.test', pin, nuevaContrasena: 'Other-pass-123' })).rejects.toThrow();
  });
  it('la renovación no reinicia la edad de sesión ni revive versiones revocadas', async () => {
    const { service, jwt, account } = setup();
    const started = Math.floor(Date.now() / 1000) - 5000;
    await service.renovarSesion({ ...account.usuario, sessionStartedAt: started, sessionVersion: 0 });
    expect(jwt.sign).toHaveBeenCalledWith(expect.objectContaining({ sessionStartedAt: started, sv: 0 }));
    await service.cerrarSesiones(1);
    await expect(service.renovarSesion({ ...account.usuario, sessionStartedAt: started, sessionVersion: 0 })).rejects.toThrow();
  });
});
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
