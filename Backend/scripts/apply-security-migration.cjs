// Ejecutor explícito de migraciones. No ejecuta el seeder.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');
const { readFileSync } = require('fs');
const { join } = require('path');

async function main() {
  const migrationUser = process.env.DB_MIGRATION_USER ?? process.env.DB_USER;
  const migrationPassword =
    process.env.DB_MIGRATION_PASSWORD ?? process.env.DB_PASSWORD;
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
  for (const key of ['DB_HOST', 'DB_NAME']) {
    if (!process.env[key]) throw new Error(`Falta ${key}`);
  }
  if (!migrationUser || !migrationPassword) {
    throw new Error(
      'Faltan DB_MIGRATION_USER/DB_MIGRATION_PASSWORD (o DB_USER/DB_PASSWORD)',
    );
  }
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    user: migrationUser,
    password: migrationPassword,
    database: process.env.DB_NAME,
    connectionTimeoutMillis: 5000,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
  });
  try {
    await client.connect();
    await client.query("SET lock_timeout = '5s'");
    const files = process.argv.includes('--normalize')
      ? [
          '20260921-normalizacion-integridad.sql',
          '20260922-consistencia-seguridad.sql',
          '20260922-propietarios-email.sql',
        ]
      : [
          '20260920-session-version.sql',
          '20260920-reserva-unica.sql',
          '20260920-resena-control.sql',
          '20260920-solicitud-correo.sql',
        ];
    for (const file of files) {
      const tableExists = await client.query(
        "SELECT to_regclass('public.schema_migrations') IS NOT NULL AS existe",
      );
      if (tableExists.rows[0].existe) {
        const applied = await client.query(
          'SELECT 1 FROM schema_migrations WHERE nombre = $1',
          [file],
        );
        if (applied.rowCount) {
          console.log(`Migración ya aplicada, se omite: ${file}`);
          continue;
        }
      }
      await client.query(
        readFileSync(join(__dirname, '../migrations', file), 'utf8'),
      );
    }
    console.log('Migración aplicada correctamente.');
  } finally {
    await client.end();
  }
}
main().catch((error) => {
  const detail =
    error && typeof error === 'object' && 'detail' in error && error.detail
      ? ` Detalle: ${String(error.detail)}`
      : '';
  console.error(
    `No se aplicó la migración: ${error instanceof Error ? error.message : String(error)}.${detail} No se ejecutó el seeder.`,
  );
  process.exitCode = 1;
});
