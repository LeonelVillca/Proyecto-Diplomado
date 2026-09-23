// Vista previa de los datos de demostración que eliminará la migración.
require('dotenv').config({ quiet: true });
const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
  });
  try {
    await client.connect();
    const result = await client.query(`
      WITH objetivos AS (
        SELECT id_usuario, correo
        FROM usuarios
        WHERE lower(correo) ~ '^restaurante([1-9]|1[0-9]|20)@mesachapaca\\.com$'
      ), restaurantes_objetivo AS (
        SELECT id_restaurante
        FROM restaurante
        WHERE lower(correo) IN (SELECT lower(correo) FROM objetivos)
           OR id_solicitud IN (
             SELECT id_solicitud FROM solicitud
             WHERE id_usuario IN (SELECT id_usuario FROM objetivos)
           )
      )
      SELECT
        (SELECT count(*) FROM objetivos)::int AS usuarios,
        (SELECT count(*) FROM restaurantes_objetivo)::int AS restaurantes,
        (SELECT count(*) FROM reservas
         WHERE id_usuario IN (SELECT id_usuario FROM objetivos)
            OR id_mesa IN (
              SELECT id_mesa FROM mesa
              WHERE id_restaurante IN (SELECT id_restaurante FROM restaurantes_objetivo)
            ))::int AS reservas
    `);
    console.log(JSON.stringify(result.rows[0]));
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('No se pudo generar la vista previa:', error.message);
  process.exitCode = 1;
});
