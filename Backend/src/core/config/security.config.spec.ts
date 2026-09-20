import { ConfigService } from '@nestjs/config';
import { jwtSecret, originAllowed, validateSecurityEnvironment } from './security.config';

describe('Configuración de seguridad', () => {
  const base = { NODE_ENV: 'production', DB_HOST: 'db', DB_USER: 'app', DB_NAME: 'app', DB_PASSWORD: 'test-only-strong-db-password',
    JWT_SECRET: 'x'.repeat(64), PIN_HMAC_SECRET: 'y'.repeat(64), CORS_ORIGINS: 'https://app.example.test', FRONTEND_URL: 'https://app.example.test', API_PUBLIC_URL: 'https://api.example.test' };
  it('rechaza secretos vacíos, cortos y de ejemplo', () => {
    for (const value of ['', 'short', 'cambiar-por-' + 'a'.repeat(64)]) expect(() => jwtSecret(new ConfigService({ JWT_SECRET: value }))).toThrow();
  });
  it('permite móvil sin Origin y solo el dominio configurado en producción', () => {
    expect(originAllowed(undefined, base)).toBe(true);
    expect(originAllowed('https://app.example.test', base)).toBe(true);
    for (const origin of ['http://localhost:4000', 'https://evil.test', 'null', 'https://app.example.test.evil.test']) {
      expect(originAllowed(origin, base)).toBe(false);
    }
  });
  it('localhost variable solo está permitido durante desarrollo', () => {
    expect(originAllowed('http://localhost:53200', { NODE_ENV: 'development' })).toBe(true);
    expect(originAllowed('http://localhost:53200.evil.test', { NODE_ENV: 'development' })).toBe(false);
  });
  it('valida producción y rechaza valores locales/incompletos', () => {
    expect(validateSecurityEnvironment(base)).toEqual(base);
    for (const overrides of [{ FRONTEND_URL: 'http://app.example.test' }, { API_PUBLIC_URL: '' }, { API_PUBLIC_URL: 'http://api.example.test' }, { CORS_ORIGINS: '' }, { DB_PASSWORD: '12345' }, { DB_HOST: '' }, { PIN_HMAC_SECRET: '' }, { PIN_HMAC_SECRET: base.JWT_SECRET }, { JWT_EXPIRES_IN: '7d' }, { NODE_ENV: '' }]) {
      expect(() => validateSecurityEnvironment({ ...base, ...overrides })).toThrow();
    }
  });
});
