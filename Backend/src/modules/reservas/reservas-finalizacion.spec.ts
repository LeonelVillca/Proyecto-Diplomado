import { ReservasFinalizacionService } from './reservas-finalizacion.service';

describe('Finalización automática de reservas', () => {
  it('finaliza únicamente reservas confirmadas cuyo tiempo terminó y comunica el cambio', async () => {
    let sql = '';
    const query = jest.fn((statement: string) => {
      sql = statement;
      return Promise.resolve([[{ id: 12, idUsuario: 3, idRestaurante: 7 }], 1]);
    });
    const gateway = { emitActualizacionReserva: jest.fn() };
    const service = new ReservasFinalizacionService(
      { query } as any,
      gateway as any,
    );

    await expect(service.finalizarVencidas()).resolves.toBe(1);

    expect(sql).toContain("r.estado = 'confirmada'");
    expect(sql).toContain("SET estado = 'finalizada'");
    expect(sql).toContain('r.duracion_minutos');
    expect(sql).toContain('AT TIME ZONE');
    expect(sql).toContain('<= NOW()');
    expect(gateway.emitActualizacionReserva).toHaveBeenCalledWith(
      12,
      'finalizada',
      7,
      3,
    );
  });

  it('no comunica cambios cuando no hay reservas vencidas', async () => {
    const gateway = { emitActualizacionReserva: jest.fn() };
    const service = new ReservasFinalizacionService(
      { query: jest.fn().mockResolvedValue([[], 0]) } as any,
      gateway as any,
    );

    await expect(service.finalizarVencidas()).resolves.toBe(0);
    expect(gateway.emitActualizacionReserva).not.toHaveBeenCalled();
  });
});
