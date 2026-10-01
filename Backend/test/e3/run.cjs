// Ejecuta E3 únicamente contra un clúster PostgreSQL local y dedicado.
// No carga .env ni acepta DB_HOST/DB_NAME heredados del entorno.
const { existsSync, mkdirSync } = require('fs');
const { join, resolve } = require('path');
const { spawnSync } = require('child_process');
const { randomBytes } = require('crypto');

const backend = resolve(__dirname, '../..');
const data = join(backend, '.test-postgres-runtime');
const database = 'mesa_chapaca_e3_test';
const user = 'mesa_test';
const port = '55433';
const pgBin = process.env.E3_PG_BIN || (process.platform === 'win32'
  ? 'C:\\Program Files\\PostgreSQL\\16\\bin'
  : '/usr/bin');
const executable = (name) => join(pgBin, process.platform === 'win32' ? `${name}.exe` : name);

function run(name, args, options = {}) {
  const result = spawnSync(executable(name), args, {
    cwd: backend,
    encoding: 'utf8',
    ...options,
  });
  if (result.error || result.status !== 0) {
    throw new Error(`${name} falló: ${result.error?.message || result.stderr || result.stdout}`);
  }
  return (result.stdout || '').trim();
}

function normalized(path) {
  return resolve(path).replace(/\\/g, '/').toLowerCase();
}

function main() {
  if (!existsSync(executable('initdb')) || !existsSync(executable('pg_ctl'))) {
    throw new Error('PostgreSQL 16 no está disponible. Define E3_PG_BIN con la carpeta bin de PostgreSQL.');
  }
  if (!normalized(data).startsWith(`${normalized(backend)}/`)) {
    throw new Error('El directorio de pruebas debe estar dentro de Backend.');
  }
  if (!existsSync(join(data, 'PG_VERSION'))) {
    mkdirSync(data, { recursive: true });
    run('initdb', ['-D', data, '-A', 'trust', '-U', user, '--encoding=UTF8', '--no-instructions']);
  }
  const ready = spawnSync(executable('pg_isready'), ['-h', '127.0.0.1', '-p', port], { encoding: 'utf8' });
  if (ready.status !== 0) {
    // En Windows el proceso postgres hereda los pipes capturados por spawnSync;
    // stdio heredado evita que pg_ctl quede esperando esos handles abiertos.
    run('pg_ctl', ['-D', data, '-l', join(data, 'server.log'), '-o', `-h 127.0.0.1 -p ${port}`, '-w', 'start'], { stdio: 'inherit' });
  }
  const connection = ['-h', '127.0.0.1', '-p', port, '-U', user, '-d', 'postgres'];
  const serverData = run('psql', [...connection, '-tAc', 'SHOW data_directory']);
  if (normalized(serverData) !== normalized(data)) {
    throw new Error('El puerto 55433 pertenece a otra instancia PostgreSQL; no se ejecutarán las pruebas.');
  }
  const exists = run('psql', [...connection, '-tAc', `SELECT 1 FROM pg_database WHERE datname = '${database}'`]);
  if (exists !== '1') {
    run('createdb', ['-h', '127.0.0.1', '-p', port, '-U', user, database]);
  }

  const env = {
    ...process.env,
    NODE_ENV: 'test',
    E3_INTEGRATION_TEST: '1',
    DB_HOST: '127.0.0.1', DB_PORT: port, DB_USER: user,
    DB_PASSWORD: 'local-test-cluster', DB_NAME: database, DB_SSL: 'false',
    JWT_SECRET: randomBytes(48).toString('hex'),
    PIN_HMAC_SECRET: randomBytes(48).toString('hex'),
    FIREBASE_PROJECT_ID: '', FIREBASE_CLIENT_EMAIL: '', FIREBASE_PRIVATE_KEY: '',
    BREVO_API_KEY: '', MAIL_FROM: '',
    CLOUDINARY_CLOUD_NAME: '', CLOUDINARY_API_KEY: '', CLOUDINARY_API_SECRET: '',
    R2_ACCOUNT_ID: '', R2_ACCESS_KEY_ID: '', R2_SECRET_ACCESS_KEY: '',
  };
  process.stdout.write(`Base de prueba: ${database} en 127.0.0.1:${port}\n`);
  const jest = spawnSync(process.execPath, [
    require.resolve('jest/bin/jest'), '--config', './test/jest-e3.json',
    '--runInBand', ...process.argv.slice(2),
  ], { cwd: backend, env, stdio: 'inherit' });
  if (jest.error) throw jest.error;
  process.exitCode = jest.status ?? 1;
}

try { main(); } catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}

