import { execFileSync } from 'child_process';
import { resolve } from 'path';

describe('Menor privilegio con servicios, JWT y PostgreSQL reales', () => {
  let report: any;
  beforeAll(() => {
    const output = execFileSync(
      process.execPath,
      [resolve(__dirname, 'menor-privilegio.cjs')],
      {
        cwd: resolve(__dirname, '../..'),
        env: process.env,
        encoding: 'utf8',
        timeout: 25000,
      },
    );
    report = JSON.parse(
      output
        .trim()
        .split(/\r?\n/)
        .filter((line) => line.startsWith('{'))
        .pop()!,
    );
    console.log('Evidencia menor privilegio:', JSON.stringify(report));
  });
  it('la creación compartida con Google produce cuenta sin roles ni permisos administrativos', () => {
    expect(report.clienteRoles).toEqual([]);
    expect(report.clientePermisos).toEqual([]);
    expect(report.clienteEstado).toBe(403);
    expect(report.mocks).toBe(false);
    expect(report.googleExternoEjecutado).toBe(false);
  });
  it('admin_restaurante recibe 403 en GET /api/v1/usuarios exclusivo de admin_sistema', () => {
    expect(report.adminRoles).toEqual(['admin_restaurante']);
    expect(report.adminEstado).toBe(403);
    expect(report.adminRespuesta).toEqual({
      message: 'Forbidden resource',
      error: 'Forbidden',
      statusCode: 403,
    });
  });
  it('cliente y admin_restaurante no pueden asignar roles mediante la API', () => {
    expect(report.autoasignacionEstado).toBe(403);
    expect(report.adminAsignarRolesEstado).toBe(403);
  });
});
