// Auditoría de solo lectura posterior a las migraciones.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');

async function main() {
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
    await client.query('BEGIN READ ONLY');
    const result = await client.query(`
      SELECT 'cuentas_demo' AS control, count(*)::bigint AS hallazgos
      FROM usuarios
      WHERE lower(correo) ~ '^restaurante([1-9]|1[0-9]|20)@mesachapaca\\.com$'
      UNION ALL
      SELECT 'correos_duplicados', count(*) FROM (
        SELECT lower(correo) FROM usuarios GROUP BY lower(correo) HAVING count(*) > 1
      ) q
      UNION ALL
      SELECT 'password_hash_repetido', count(*) FROM (
        SELECT password_hash FROM cuentas_auth
        WHERE password_hash IS NOT NULL
        GROUP BY password_hash HAVING count(*) > 1
      ) q
      UNION ALL
      SELECT 'tokens_sin_hash', count(*) FROM invitacion_token
      WHERE token !~ '^[0-9a-f]{64}$'
      UNION ALL
      SELECT 'mesas_sin_capacidad', count(*) FROM mesa
      WHERE capacidad IS NULL OR capacidad <= 0
      UNION ALL
      SELECT 'restaurantes_sin_propietario', count(*) FROM restaurante r
      WHERE r.eliminado_at IS NULL AND NOT EXISTS (
        SELECT 1 FROM usuario_restaurante ur
        WHERE ur.id_restaurante = r.id_restaurante AND ur.activo
      )
      UNION ALL
      SELECT 'reservas_solapadas', count(*) FROM reservas a
      JOIN reservas b ON a.id_reserva < b.id_reserva
        AND a.id_mesa = b.id_mesa
        AND a.estado IN ('pendiente', 'confirmada')
        AND b.estado IN ('pendiente', 'confirmada')
        AND tsrange(a.fecha + a.hora,
                    a.fecha + a.hora + a.duracion_minutos * interval '1 minute', '[)')
            &&
            tsrange(b.fecha + b.hora,
                    b.fecha + b.hora + b.duracion_minutos * interval '1 minute', '[)')
    `);
    const hallazgos = result.rows.filter((row) => Number(row.hallazgos) > 0);
    if (hallazgos.length) {
      throw new Error(
        `Fallaron controles de integridad: ${hallazgos
          .map((row) => `${row.control}=${row.hallazgos}`)
          .join(', ')}`,
      );
    }
    console.log('Verificación de integridad correcta: 0 hallazgos.');
  } finally {
    await client.query('ROLLBACK').catch(() => undefined);
    await client.end();
  }
}

main().catch((error) => {
  console.error('Verificación fallida:', error.message);
  process.exitCode = 1;
});
