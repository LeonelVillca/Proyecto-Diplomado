// Ejecutor explícito de migraciones. No ejecuta el seeder.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');
const { readFileSync } = require('fs');
const { join } = require('path');

async function main() {
  const localOnly = process.argv.includes('--local-only');
  if (
    localOnly &&
    (process.env.NODE_ENV === 'production' ||
      !['localhost', '127.0.0.1', '::1'].includes(process.env.DB_HOST))
  ) {
    throw new Error(
      'La migración local exige una base de datos local de desarrollo',
    );
  }
  if (!localOnly && !process.argv.includes('--apply'))
    throw new Error('Indica --local-only o --apply para aplicar la migración');
  for (const key of ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    if (!process.env[key]) throw new Error(`Falta ${key}`);
  }
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    connectionTimeoutMillis: 5000,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
  });
  try {
    await client.connect();
    await client.query("SET lock_timeout = '5s'");
    const files = process.argv.includes('--normalize')
      ? ['20260921-normalizacion-integridad.sql']
      : [
          '20260920-session-version.sql',
          '20260920-reserva-unica.sql',
          '20260920-resena-control.sql',
          '20260920-solicitud-correo.sql',
        ];
    for (const file of files) {
      await client.query(
        readFileSync(join(__dirname, '../migrations', file), 'utf8'),
      );
    }
    console.log('Migración aplicada correctamente.');
  } finally {
    await client.end();
  }
}
main().catch(() => {
  console.error(
    'No se aplicó la migración. Comprueba conexión, entorno y permisos DDL; no se ejecutó el seeder.',
  );
  process.exitCode = 1;
});
