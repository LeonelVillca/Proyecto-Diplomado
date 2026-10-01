import { execFileSync } from 'child_process';
import { resolve } from 'path';

describe('Validación inválida de reserva con API y PostgreSQL reales', () => {
  it('numeroPersonas=0 devuelve 400 y no persiste una reserva (sin mocks)', () => {
    const output = execFileSync(
      process.execPath,
      [resolve(__dirname, 'reserva-validacion.cjs')],
      {
        cwd: resolve(__dirname, '../..'),
        env: process.env,
        encoding: 'utf8',
        timeout: 25000,
      },
    );
    const report = JSON.parse(
      output
        .trim()
        .split(/\r?\n/)
        .filter((line) => line.startsWith('{'))
        .pop()!,
    );
    expect(report.status).toBe(400);
    expect(report.body).toEqual({
      message: ['numeroPersonas must not be less than 1'],
      error: 'Bad Request',
      statusCode: 400,
    });
    expect(report.reservasDespues).toBe(report.reservasAntes);
    expect(report.mocks).toBe(false);
    console.log('Evidencia HTTP + PostgreSQL:', JSON.stringify(report));
  });
});
