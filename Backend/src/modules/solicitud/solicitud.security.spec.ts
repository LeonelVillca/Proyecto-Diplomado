import { SolicitudService } from './solicitud.service';
import { Solicitud } from './solicitud.entity';
import { Restaurante } from '../restaurante/restaurante.entity';
import { Rol } from '../rol/rol.entity';

describe('Aprobación de solicitudes', () => {
  it('no deja aprobar solicitudes nuevas sin correo confirmado', async () => {
    const solicitud = { id: 5, estado: 'pendiente', correoVerificadoAt: null, usuario: { id: 2, correo: 'u@example.test' } };
    const repo = { findOne: async () => solicitud };
    const manager = { findOne: jest.fn(async () => solicitud) };
    const source = { transaction: async (callback: (manager: unknown) => Promise<unknown>) => callback(manager) };
    const service = new SolicitudService(repo as any, {} as any, source as any, {} as any);
    await expect(service.actualizar(5, { estado: 'aprobada' })).rejects.toThrow('no confirmó su correo');
    expect(manager.findOne).toHaveBeenCalledTimes(1);
  });

  it('consume el enlace de verificación una sola vez dentro de una transacción', async () => {
    const manager = { query: jest.fn()
      .mockResolvedValueOnce([{ id_solicitud: 5 }])
      .mockResolvedValueOnce([{ id_solicitud: 5 }])
      .mockResolvedValueOnce([]) };
    const source = { transaction: jest.fn(async (callback: (manager: unknown) => Promise<unknown>) => callback(manager)) };
    const service = new SolicitudService({} as any, {} as any, source as any, {} as any);
    await expect(service.verificarCorreo('a'.repeat(64))).resolves.toEqual(expect.objectContaining({ mensaje: expect.any(String) }));
    expect(manager.query).toHaveBeenCalledTimes(3);
    expect(manager.query.mock.calls[2][0]).toContain('DELETE FROM solicitud_verificacion');
    await expect(service.verificarCorreo('invalido')).rejects.toThrow('inválido');
  });

  it('limita el reenvío por solicitud sin revelar si existe el correo', async () => {
    const solicitud = { id: 5, estado: 'pendiente', usuario: { correo: 'u@example.test' } };
    const repo = { findOne: jest.fn(async () => solicitud) };
    const manager = { query: jest.fn(async () => [{ enviado_at: new Date() }]) };
    const source = { transaction: async (callback: (manager: unknown) => Promise<unknown>) => callback(manager) };
    const mail = { enviarVerificacionSolicitud: jest.fn() };
    const service = new SolicitudService(repo as any, {} as any, source as any, mail as any);
    const result = await service.reenviarVerificacion('u@example.test');
    expect(result.mensaje).toContain('Si hay una solicitud');
    expect(mail.enviarVerificacionSolicitud).not.toHaveBeenCalled();
  });

  it('impide reabrir una solicitud rechazada sin crear restaurante ni rol', async () => {
    const repo = { findOne: jest.fn(async () => ({ id: 5, estado: 'rechazada', usuario: { id: 2 } })), save: jest.fn() };
    const source = { transaction: jest.fn() };
    const service = new SolicitudService(repo as any, {} as any, source as any, {} as any);
    await expect(service.actualizar(5, { estado: 'aprobada' })).rejects.toThrow('no puede cambiar de estado');
    expect(repo.save).not.toHaveBeenCalled();
    expect(source.transaction).not.toHaveBeenCalled();
  });

  it('propaga errores de creación de restaurante sin enviar invitación ni guardar aprobación fuera de la transacción', async () => {
    const solicitud = { id: 5, estado: 'pendiente', correoVerificadoAt: new Date(), usuario: { id: 2, correo: 'u@example.test' }, nombreRestaurante: 'Ejemplo' };
    const repo = { findOne: jest.fn(async () => ({ ...solicitud })), save: jest.fn() };
    const manager = {
      findOne: jest.fn(async (entity: unknown) => entity === Solicitud ? { ...solicitud } : entity === Rol ? { id: 3 } : null),
      create: jest.fn((entity: any, value: any) => Object.assign(new entity(), value)),
      save: jest.fn(async (value: any) => {
        if (value instanceof Restaurante) throw new Error('Fallo de base de datos');
        return value;
      }),
      update: jest.fn(async () => {}),
    };
    const source = { transaction: jest.fn(async (callback: (manager: unknown) => Promise<unknown>) => callback(manager)) };
    const mail = { enviarInvitacion: jest.fn() };
    const service = new SolicitudService(repo as any, {} as any, source as any, mail as any);
    await expect(service.actualizar(5, { estado: 'aprobada' })).rejects.toThrow('Fallo de base de datos');
    expect(source.transaction).toHaveBeenCalledTimes(1);
    expect(repo.save).not.toHaveBeenCalled();
    expect(mail.enviarInvitacion).not.toHaveBeenCalled();
  });
});
