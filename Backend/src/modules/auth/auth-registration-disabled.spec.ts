import { readFileSync } from 'fs';
import { join } from 'path';

describe('Registro local público deshabilitado', () => {
  it('no expone POST /auth/register ni conserva su lógica de emisión de JWT', () => {
    const controller = readFileSync(
      join(__dirname, 'auth.controller.ts'),
      'utf8',
    );
    const service = readFileSync(join(__dirname, 'auth.service.ts'), 'utf8');

    expect(controller).not.toContain("@Post('register')");
    expect(service).not.toMatch(/async\s+registro\s*\(/);
  });
});
