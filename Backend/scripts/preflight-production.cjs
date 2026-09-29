// Comprobaciones de despliegue de solo lectura. No imprime credenciales.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');
const {
  validateSecurityEnvironment,
} = require('../dist/src/core/config/security.config');

async function main() {
  if (process.env.NODE_ENV !== 'production') {
    throw new Error('NODE_ENV debe ser production');
  }
  validateSecurityEnvironment(process.env);
  const missing = [
    'BREVO_API_KEY',
    'MAIL_FROM',
    'FIREBASE_PROJECT_ID',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_PRIVATE_KEY',
  ].filter((name) => !process.env[name]);
  if (missing.length)
    throw new Error(`Faltan variables: ${missing.join(', ')}`);

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
        EXISTS (SELECT 1 FROM pg_constraint
                WHERE conname = 'ex_reserva_mesa_intervalo_activo') AS reservas,
        EXISTS (SELECT 1 FROM pg_constraint
                WHERE conname = 'ex_horario_sin_solapamiento') AS horarios,
        to_regclass('resena_creacion_control') IS NOT NULL AS resenas,
        to_regclass('solicitud_verificacion') IS NOT NULL AS correo,
        to_regclass('usuario_restaurante') IS NOT NULL AS propietarios,
        to_regclass('auditoria_evento') IS NOT NULL AS auditoria,
        to_regclass('mesa_bloqueo_horario') IS NOT NULL AS bloqueos_mesa,
        CASE WHEN to_regclass('mesa_bloqueo_horario') IS NOT NULL
          THEN has_table_privilege(current_user, 'mesa_bloqueo_horario', 'SELECT')
            AND has_table_privilege(current_user, 'mesa_bloqueo_horario', 'INSERT')
            AND has_table_privilege(current_user, 'mesa_bloqueo_horario', 'UPDATE')
            AND has_table_privilege(current_user, 'mesa_bloqueo_horario', 'DELETE')
          ELSE false END AS permisos_bloqueos_mesa,
        EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = current_schema() AND table_name = 'solicitud'
                  AND column_name = 'correo_verificado_at') AS columna_correo,
        EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = current_schema() AND table_name = 'cuentas_auth'
                  AND column_name = 'session_version') AS sesiones
    `);
    const checks = result.rows[0];
    const pendientes = Object.entries(checks)
      .filter(([, value]) => !value)
      .map(([name]) => name);
    if (pendientes.length)
      throw new Error(`Migraciones pendientes: ${pendientes.join(', ')}`);

    const security = await client.query(`
      SELECT
        ssl.ssl AS conexion_ssl,
        NOT rol.rolsuper AS no_superusuario,
        NOT rol.rolcreatedb AS no_crear_bases,
        NOT rol.rolcreaterole AS no_crear_roles,
        NOT rol.rolbypassrls AS no_omitir_rls,
        NOT has_schema_privilege(current_user, 'public', 'CREATE') AS no_crear_esquema
      FROM pg_roles rol
      JOIN pg_stat_ssl ssl ON ssl.pid = pg_backend_pid()
      WHERE rol.rolname = current_user
    `);
    const controles = security.rows[0] ?? {};
    const inseguros = Object.entries(controles)
      .filter(([, value]) => !value)
      .map(([name]) => name);
    if (inseguros.length) {
      throw new Error(
        `Configuración PostgreSQL insegura: ${inseguros.join(', ')}`,
      );
    }
    console.log(
      'Preflight de producción correcto: entorno, credenciales presentes y esquema de BD.',
    );
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('Preflight falló:', error.message);
  process.exitCode = 1;
});
