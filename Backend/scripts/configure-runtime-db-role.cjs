// Crea/endurece el rol usado por la API. Requiere credenciales administrativas separadas.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');

async function formatted(client, template, values) {
  const result = await client.query(
    `SELECT format($fmt$${template}$fmt$, $1, $2) AS sql`,
    values,
  );
  return result.rows[0].sql;
}

async function main() {
  if (!process.argv.includes('--apply')) {
    throw new Error('Indica --apply para configurar el rol de ejecución.');
  }
  const appUser = process.env.DB_USER;
  const appPassword = process.env.DB_PASSWORD;
  const adminUser = process.env.DB_MIGRATION_USER;
  const adminPassword = process.env.DB_MIGRATION_PASSWORD;
  const database = process.env.DB_NAME;
  if (!appUser || !appPassword || !adminUser || !adminPassword || !database) {
    throw new Error(
      'Configura DB_USER, DB_PASSWORD, DB_MIGRATION_USER, DB_MIGRATION_PASSWORD y DB_NAME.',
    );
  }
  if (appUser === adminUser) {
    throw new Error('DB_USER debe ser distinto de DB_MIGRATION_USER.');
  }
  if (!/^[a-z_][a-z0-9_-]{0,62}$/i.test(appUser)) {
    throw new Error('DB_USER contiene caracteres no permitidos.');
  }

  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    user: adminUser,
    password: adminPassword,
    database,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
  });
  try {
    await client.connect();
    const exists = await client.query(
      'SELECT 1 FROM pg_roles WHERE rolname = $1',
      [appUser],
    );
    const roleSql = await formatted(
      client,
      exists.rowCount
        ? 'ALTER ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS'
        : 'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS',
      [appUser, appPassword],
    );
    await client.query('BEGIN');
    await client.query(roleSql);
    const databaseSql = (
      await client.query(
        "SELECT format('GRANT CONNECT ON DATABASE %I TO %I', $1, $2) AS sql",
        [database, appUser],
      )
    ).rows[0].sql;
    await client.query(databaseSql);
    const roleIdent = (
      await client.query("SELECT format('%I', $1) AS id", [appUser])
    ).rows[0].id;
    await client.query(`GRANT USAGE ON SCHEMA public TO ${roleIdent}`);
    await client.query(`REVOKE CREATE ON SCHEMA public FROM ${roleIdent}`);
    await client.query(
      `GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${roleIdent}`,
    );
    await client.query(
      `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${roleIdent}`,
    );
    await client.query(
      `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${roleIdent}`,
    );
    await client.query(
      `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO ${roleIdent}`,
    );
    await client.query(
      `REVOKE UPDATE, DELETE, TRUNCATE ON auditoria_evento FROM ${roleIdent}`,
    );
    await client.query('COMMIT');
    console.log('Rol de ejecución configurado con privilegios mínimos.');
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('No se configuró el rol:', error.message);
  process.exitCode = 1;
});
