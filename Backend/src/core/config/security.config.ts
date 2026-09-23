import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';

export function jwtSecret(config: ConfigService): string {
  const secret = config.get<string>('JWT_SECRET');
  if (
    !secret ||
    secret.length < 32 ||
    /cambiar-por|secreto|diplomado|ejemplo|local|test|demo|password|default/i.test(
      secret,
    )
  ) {
    throw new Error(
      'JWT_SECRET debe contener al menos 32 caracteres aleatorios, sin valores de ejemplo.',
    );
  }
  return secret;
}

export function pinHmacSecret(config: ConfigService): string {
  const separate = config.get<string>('PIN_HMAC_SECRET');
  if (separate) {
    if (
      separate.length < 32 ||
      separate === jwtSecret(config) ||
      /cambiar-por|secreto|ejemplo|local|test|demo|password|default/i.test(
        separate,
      )
    ) {
      throw new Error(
        'PIN_HMAC_SECRET debe ser aleatorio, independiente del secreto JWT y de al menos 32 caracteres.',
      );
    }
    return separate;
  }
  if (config.get<string>('NODE_ENV') === 'production') {
    throw new Error('Configura PIN_HMAC_SECRET para producción.');
  }
  // Compatibilidad local: clave derivada y separada por dominio hasta configurar la variable.
  return createHmac('sha256', jwtSecret(config))
    .update('pin-hmac-development-only')
    .digest('hex');
}

export const AUTH_RATE_LIMITS = [{ name: 'default', ttl: 60000, limit: 100 }];

export function originAllowed(origin?: string, env = process.env): boolean {
  // Los clientes nativos no envían Origin. Esto no sustituye autenticación.
  if (!origin) return true;
  const allowed = (env.CORS_ORIGINS ?? '')
    .split(',')
    .map((item) => item.trim());
  if (allowed.includes(origin)) return true;
  return (
    env.NODE_ENV === 'development' &&
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
  );
}

export function validateSecurityEnvironment(env: Record<string, any>) {
  if (!['development', 'test', 'production'].includes(env.NODE_ENV)) {
    throw new Error(
      'Configura NODE_ENV explícitamente como development, test o production.',
    );
  }
  jwtSecret(new ConfigService(env));
  pinHmacSecret(new ConfigService(env));
  if (env.JWT_EXPIRES_IN && env.JWT_EXPIRES_IN !== '1h') {
    throw new Error(
      'JWT_EXPIRES_IN debe ser 1h; la renovación conserva una sesión de hasta 7 días.',
    );
  }
  for (const key of ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    if (!env[key]) throw new Error(`Falta configurar ${key}`);
  }
  if (env.NODE_ENV === 'production') {
    if (env.DB_SSL !== 'true') {
      throw new Error('DB_SSL=true es obligatorio en producción.');
    }
    if (!env.API_PUBLIC_URL)
      throw new Error(
        'Configura API_PUBLIC_URL para los enlaces de verificación.',
      );
    const origins = (env.CORS_ORIGINS ?? '').split(',').filter(Boolean);
    if (!origins.length)
      throw new Error('Configura CORS_ORIGINS para producción.');
    for (const value of [...origins, env.FRONTEND_URL, env.API_PUBLIC_URL]) {
      const url = new URL(value);
      if (
        url.protocol !== 'https:' ||
        /^(localhost|127\.0\.0\.1)$/.test(url.hostname) ||
        url.username ||
        url.password
      ) {
        throw new Error(
          'CORS_ORIGINS, FRONTEND_URL y API_PUBLIC_URL deben usar dominios HTTPS de producción.',
        );
      }
    }
    if (['12345', 'postgres', 'password'].includes(env.DB_PASSWORD)) {
      throw new Error(
        'No se permiten contraseñas de base de datos de ejemplo en producción.',
      );
    }
  }
  return env;
}
