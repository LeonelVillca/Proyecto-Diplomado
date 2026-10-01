# Integración API + PostgreSQL para E3

Desde `Backend`, ejecutar `npm run test:e3`. Se requieren Node/npm, las dependencias del proyecto instaladas y PostgreSQL 16 local. En Windows, el lanzador busca los ejecutables en `C:\Program Files\PostgreSQL\16\bin`; si están en otra carpeta, definir `E3_PG_BIN` con la ruta de `bin` antes de ejecutar. No hay otras variables que configurar manualmente.

El lanzador crea/usa exclusivamente el clúster local `Backend/.test-postgres-runtime`, puerto `55433`, y la base `mesa_chapaca_e3_test`. Ambos directorios de prueba están ignorados por Git. Antes de crear el esquema y limpiar tablas, verifica que el puerto corresponde a ese clúster. El esquema se recrea en cada ejecución y los datos se limpian entre tests y al finalizar. El comando asigna variables `DB_*`, `JWT_SECRET`, `PIN_HMAC_SECRET` y `E3_INTEGRATION_TEST` solo al proceso de Jest; Nest ignora `.env` en este modo. Nunca usar este comando con datos reales.

Las 14 pruebas pasan por HTTP NestJS, controladores, guards, servicios, TypeORM y PostgreSQL reales. Los administradores reciben JWT mediante `/api/v1/auth/login`, que usa la comparación bcrypt real. Para RF-01, **solo** `FirebaseAdminService.verificarIdToken` se sustituye por una identidad controlada; la verificación externa de Google/Firebase no queda probada aquí. El endpoint, `AuthService`, persistencia y emisión del JWT propio sí son reales.

Las migraciones del repositorio son incrementales y no crean el esquema inicial. Por eso esta suite genera las tablas con TypeORM **solo en la base aislada**, aplica las reglas SQL de horario/bloqueo de reservas y crea la tabla de auditoría necesaria para arrancar la app. No cambia el esquema de producción.


La suite original contiene 14 pruebas; con salud (1), validación 400 (1) y menor privilegio (3), el comando completo ejecuta 19. Los resultados sanitizados están en Backend/reports. Ejecuta npm run build antes de la suite completa: validación y menor privilegio usan el backend compilado, sin mocks. Para regenerar evidencias, consulta la sección 11 del README raíz.
