// Comprobaciones de despliegue de solo lectura. No imprime credenciales.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');
const { validateSecurityEnvironment } = require('../dist/src/core/config/security.config');

async function main() {
  if (process.env.NODE_ENV !== 'production') {
    throw new Error('NODE_ENV debe ser production');
  }
  validateSecurityEnvironment(process.env);
  const missing = [
    'MAIL_HOST', 'MAIL_USER', 'MAIL_PASS', 'MAIL_FROM',
    'FIREBASE_PROJECT_ID', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_PRIVATE_KEY',
  ].filter((name) => !process.env[name]);
  if (missing.length) throw new Error(`Faltan variables: ${missing.join(', ')}`);

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
    const result = await client.query(`
      SELECT
        to_regclass('uq_reserva_mesa_horario_activa') IS NOT NULL AS reservas,
        to_regclass('resena_creacion_control') IS NOT NULL AS resenas,
        to_regclass('solicitud_verificacion') IS NOT NULL AS correo,
        EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = current_schema() AND table_name = 'solicitud'
                  AND column_name = 'correo_verificado_at') AS columna_correo,
        EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = current_schema() AND table_name = 'cuentas_auth'
                  AND column_name = 'session_version') AS sesiones
    `);
    const checks = result.rows[0];
    const pendientes = Object.entries(checks).filter(([, value]) => !value).map(([name]) => name);
    if (pendientes.length) throw new Error(`Migraciones pendientes: ${pendientes.join(', ')}`);
    console.log('Preflight de producción correcto: entorno, credenciales presentes y esquema de BD.');
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('Preflight falló:', error.message);
  process.exitCode = 1;
});
