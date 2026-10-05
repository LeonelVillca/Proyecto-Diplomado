import { ConfigService } from '@nestjs/config';
import { CuentaAuth } from '../../cuentas-auth/cuenta-auth.entity';
import { AccesoService } from '../services/acceso.service';
import { SesionesService } from '../services/sesiones.service';
import { ContrasenasService } from '../services/contrasenas.service';
import { RecuperacionService } from '../services/recuperacion.service';

jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));

const secret = 'a'.repeat(64);

export function setup() {
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
    query: jest.fn(async (_sql: string, _parameters: unknown[]) => [
      { id_token: 1 },
    ]),
    save: jest.fn(async (value) => value),
    findOne: jest.fn(async (entity: unknown, _options: unknown) =>
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
  const sesiones = new SesionesService(
    users as any,
    accounts as any,
    jwt as any,
    source as any,
  );
  const acceso = new AccesoService(
    users as any,
    accounts as any,
    {} as any,
    google as any,
    sesiones,
  );
  const contrasenas = new ContrasenasService(source as any);
  const recuperacion = new RecuperacionService(
    users as any,
    accounts as any,
    source as any,
    mail as any,
    new ConfigService({ JWT_SECRET: secret }),
  );
  const service = {
    loginGoogle: (dto: Parameters<AccesoService['loginGoogle']>[0]) =>
      acceso.loginGoogle(dto),
    crearContrasena: (
      dto: Parameters<ContrasenasService['crearContrasena']>[0],
    ) => contrasenas.crearContrasena(dto),
    solicitarRecuperacion: (
      dto: Parameters<RecuperacionService['solicitarRecuperacion']>[0],
    ) => recuperacion.solicitarRecuperacion(dto),
    verificarPinRecuperacion: (
      dto: Parameters<RecuperacionService['verificarPinRecuperacion']>[0],
    ) => recuperacion.verificarPinRecuperacion(dto),
    restablecerPassword: (
      dto: Parameters<RecuperacionService['restablecerPassword']>[0],
    ) => recuperacion.restablecerPassword(dto),
    renovarSesion: (usuario: Parameters<SesionesService['renovarSesion']>[0]) =>
      sesiones.renovarSesion(usuario),
    cerrarSesiones: (id: number) => sesiones.cerrarSesiones(id),
  };
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
