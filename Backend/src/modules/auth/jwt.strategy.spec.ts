import { ConfigService } from '@nestjs/config';
import { JwtStrategy } from './jwt.strategy';
import { JwtService } from '@nestjs/jwt';

describe('Sesiones revocables', () => {
  const secret = 'a'.repeat(64);
  const now = Math.floor(Date.now() / 1000);
  const payload = { sub: 1, correo: 'test@example.test', sv: 3, sessionStartedAt: now - 30, exp: now + 3600 };
  let account: any;
  let strategy: JwtStrategy;
  beforeEach(() => {
    account = { estado: true, sessionVersion: 3, usuario: { id: 1, estado: 'activo' } };
    strategy = new JwtStrategy(new ConfigService({ JWT_SECRET: secret }), {} as any, {
      buscarPorUsuario: jest.fn(async () => account),
    } as any);
  });
  it('acepta la sesión activa', async () => { expect((await strategy.validate(payload)).id).toBe(1); });
  it.each(['suspended-account', 'suspended-user', 'revoked', 'deleted'])('rechaza %s', async (caseName) => {
    if (caseName === 'suspended-account') account.estado = false;
    if (caseName === 'suspended-user') account.usuario.estado = 'suspendido';
    if (caseName === 'revoked') account.sessionVersion++;
    if (caseName === 'deleted') account = null;
    await expect(strategy.validate(payload)).rejects.toThrow();
  });
  it.each([{ exp: 0 }, { sv: undefined }, { sessionStartedAt: now - 7 * 86400 }, { sessionStartedAt: now + 1 }, { sub: -1 }])(
    'rechaza claims inválidos %j', async (changes) => { await expect(strategy.validate({ ...payload, ...changes } as any)).rejects.toThrow(); });
  it('rechaza firma, audiencia y algoritmo ajenos', async () => {
    const jwt = new JwtService({ secret, verifyOptions: { algorithms: ['HS256'], issuer: 'mesa-chapaca', audience: 'mesa-chapaca-app' } });
    for (const options of [{ secret: 'wrong' }, { audience: 'evil' }, { algorithm: 'HS384' as const }]) {
      const token = jwt.sign({ sub: 1 }, { issuer: 'mesa-chapaca', audience: 'mesa-chapaca-app', expiresIn: 60, ...options });
      await expect(jwt.verifyAsync(token)).rejects.toThrow();
    }
  });
});
