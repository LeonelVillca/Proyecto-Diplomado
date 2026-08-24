const { Client } = require('pg');
const client = new Client({
  user: 'postgres',
  password: '12345',
  host: 'localhost',
  port: 5432,
  database: 'restaurantes_tarija',
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
