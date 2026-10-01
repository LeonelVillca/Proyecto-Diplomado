// Solo API y PostgreSQL locales de E3. No sustituye servicios con mocks.
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
    UsuariosService,
  } = require('../../dist/src/modules/usuarios/usuarios.service');
  const {
    CuentasAuthService,
  } = require('../../dist/src/modules/cuentas-auth/cuentas-auth.service');
  const {
    UsuarioRolService,
  } = require('../../dist/src/modules/usuario-rol/usuario-rol.service');
  const {
    UsuarioRol,
  } = require('../../dist/src/modules/usuario-rol/usuario-rol.entity');
  const { Rol } = require('../../dist/src/modules/rol/rol.entity');
  const { AuthService } = require('../../dist/src/modules/auth/auth.service');
  const app = await NestFactory.create(AppModule, { logger: false });
  let db;
  let user;
  let fixtureRole;
  try {
    db = app.get(DataSource);
    assert.equal(
      (await db.query('SELECT current_database() AS nombre'))[0].nombre,
      'mesa_chapaca_e3_test',
    );
    const location = await db.query('SHOW data_directory');
    const normalize = (p) => resolve(p).replace(/\\/g, '/').toLowerCase();
    assert.equal(
      normalize(location[0].data_directory),
      normalize(resolve(__dirname, '../../.test-postgres-runtime')),
    );
    // Se reutiliza el rol existente. Si la base E3 está vacía, la fixture usa
    // el mismo nombre definido en el proyecto y se elimina al terminar.
    const roles = db.getRepository(Rol);
    let restaurantRole = await roles.findOneBy({ nombre: 'admin_restaurante' });
    if (!restaurantRole) {
      restaurantRole = await roles.save(
        roles.create({ nombre: 'admin_restaurante' }),
      );
      fixtureRole = restaurantRole;
    }
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    // Son los mismos métodos de creación que usa loginGoogle tras verificar Firebase.
    // Esta prueba NO ejecuta ni simula la verificación externa de Google.
    user = await app
      .get(UsuariosService)
      .crear({
        nombre: 'Menor privilegio E3',
        correo: `privilegios-${randomUUID()}@example.test`,
      });
    const cuenta = await app.get(CuentasAuthService).asegurarCuenta(user.id);
    const auth = app.get(AuthService);
    const session = {
      ...user,
      sessionStartedAt: Math.floor(Date.now() / 1000),
      sessionVersion: cuenta.sessionVersion,
    };
    const cliente = await auth.renovarSesion(session);
    const decoded = app.get(JwtService).verify(cliente.token);
    assert.deepEqual(decoded.permisos, []);
    assert.equal(
      await db
        .getRepository(UsuarioRol)
        .count({ where: { idUsuario: user.id } }),
      0,
    );
    const perfil = await request(app.getHttpServer())
      .get('/api/v1/auth/perfil')
      .set('Authorization', `Bearer ${cliente.token}`)
      .expect(200);
    assert.deepEqual(perfil.body.roles, []);
    const denegadoCliente = await request(app.getHttpServer())
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${cliente.token}`)
      .expect(403);
    const autoasignacion = await request(app.getHttpServer())
      .post('/api/v1/usuario-rol')
      .set('Authorization', `Bearer ${cliente.token}`)
      .send({ idUsuario: user.id, idRol: restaurantRole.id })
      .expect(403);
    assert.equal(
      await db
        .getRepository(UsuarioRol)
        .count({ where: { idUsuario: user.id } }),
      0,
    );
    // Elevación explícita únicamente del usuario temporal de prueba.
    await app
      .get(UsuarioRolService)
      .asignarRol({ idUsuario: user.id, idRol: restaurantRole.id });
    const admin = await auth.renovarSesion(session);
    const adminPerfil = await request(app.getHttpServer())
      .get('/api/v1/auth/perfil')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    assert.deepEqual(adminPerfil.body.roles, ['admin_restaurante']);
    const denegadoAdmin = await request(app.getHttpServer())
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(403);
    const denegadaAsignacion = await request(app.getHttpServer())
      .post('/api/v1/usuario-rol')
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ idUsuario: user.id, idRol: restaurantRole.id })
      .expect(403);
    console.log(
      JSON.stringify({
        clienteRoles: perfil.body.roles,
        clientePermisos: decoded.permisos,
        clienteEstado: denegadoCliente.status,
        autoasignacionEstado: autoasignacion.status,
        adminRoles: adminPerfil.body.roles,
        adminPermisos: app.get(JwtService).verify(admin.token).permisos,
        adminEstado: denegadoAdmin.status,
        adminRespuesta: denegadoAdmin.body,
        adminAsignarRolesEstado: denegadaAsignacion.status,
        mocks: false,
        googleExternoEjecutado: false,
      }),
    );
  } finally {
    if (db && user) await db.getRepository(Usuario).delete(user.id);
    if (db && fixtureRole) await db.getRepository(Rol).delete(fixtureRole.id);
    await app.close();
  }
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
