const { Client } = require('pg');
require('dotenv').config({ quiet: true });
if (process.env.NODE_ENV === 'production' || process.env.ALLOW_LOCAL_SCHEMA_CHANGE !== 'true') {
  throw new Error('Script manual bloqueado. Usa migraciones para producción.');
}
if (!process.env.DB_PASSWORD) throw new Error('Falta DB_PASSWORD');
const client = new Client({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  database: process.env.DB_NAME,
});
client.connect().then(() => {
  console.log("Connected");
  client.query('ALTER TABLE plato ADD COLUMN foto_url varchar;').then(() => {
    console.log("Column added");
    client.end();
  }).catch(err => {
    console.log(err.message);
    client.end();
  });
});
