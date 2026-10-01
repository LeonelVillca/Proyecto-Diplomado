// Prueba HTTP real: sin mocks, sin .env y solo contra el clúster exclusivo E3.
const assert = require('node:assert/strict');
const { resolve } = require('node:path');
const { randomUUID } = require('node:crypto');
const { NestFactory } = require('@nestjs/core');
const { ValidationPipe } = require('@nestjs/common');
const { JwtService } = require('@nestjs/jwt');
const { DataSource } = require('typeorm');
const request = require('supertest');

async function main() {
  assert.equal(process.env.E3_INTEGRATION_TEST, '1');
  assert.equal(process.env.DB_HOST, '127.0.0.1');
  assert.equal(process.env.DB_PORT, '55433');
  assert.equal(process.env.DB_NAME, 'mesa_chapaca_e3_test');
  const { AppModule } = require('../../dist/src/app.module');
  const { Usuario } = require('../../dist/src/modules/usuarios/usuario.entity');
  const {
    CuentaAuth,
  } = require('../../dist/src/modules/cuentas-auth/cuenta-auth.entity');
  const { Reserva } = require('../../dist/src/modules/reservas/reserva.entity');
  const app = await NestFactory.create(AppModule, { logger: false });
  let db;
  let user;
  try {
    db = app.get(DataSource);
    const identity = await db.query('SELECT current_database() AS nombre');
    assert.equal(identity[0].nombre, 'mesa_chapaca_e3_test');
    const location = await db.query('SHOW data_directory');
    const normalize = (p) => resolve(p).replace(/\\/g, '/').toLowerCase();
    assert.equal(
      normalize(location[0].data_directory),
      normalize(resolve(__dirname, '../../.test-postgres-runtime')),
    );
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    const users = db.getRepository(Usuario);
    user = await users.save(
      users.create({
        nombre: 'Validacion E3',
        correo: `validacion-${randomUUID()}@example.test`,
        estado: 'activo',
      }),
    );
    const accounts = db.getRepository(CuentaAuth);
    await accounts.save(
      accounts.create({ usuario: user, estado: true, sessionVersion: 0 }),
    );
    // JWT firmado por el servicio real; el guard consulta la cuenta real en PostgreSQL.
    const token = app
      .get(JwtService)
      .sign({
        sub: user.id,
        correo: user.correo,
        sv: 0,
        sessionStartedAt: Math.floor(Date.now() / 1000),
      });
    await request(app.getHttpServer())
      .get('/api/v1/auth/perfil')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const repo = db.getRepository(Reserva);
    const before = await repo.count();
    const body = {
      idUsuario: user.id,
      idMesa: 1,
      fecha: '2026-10-03',
      hora: '18:00',
      duracionMinutos: 60,
      numeroPersonas: 0,
    };
    const response = await request(app.getHttpServer())
      .post('/api/v1/reservas')
      .set('Authorization', `Bearer ${token}`)
      .send(body)
      .expect(400);
    assert.deepEqual(response.body, {
      message: ['numeroPersonas must not be less than 1'],
      error: 'Bad Request',
      statusCode: 400,
    });
    const after = await repo.count();
    assert.equal(after, before);
    assert.equal(await repo.count({ where: { usuario: { id: user.id } } }), 0);
    console.log(
      JSON.stringify({
        status: response.status,
        body: response.body,
        reservasAntes: before,
        reservasDespues: after,
        autenticacionReal: true,
        mocks: false,
      }),
    );
  } finally {
    // Solo se elimina la identidad creada por esta prueba; no se borran reservas.
    if (db && user) await db.getRepository(Usuario).delete(user.id);
    await app.close();
  }
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
