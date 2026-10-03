# Mesa Chapaca

> Trabajo Final · Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026  
> Autor: Leonel Fernando Villca Ortega

## 1. Descripción

Mesa Chapaca es un sistema web y móvil orientado a la consulta de restaurantes y la gestión de reservas en Tarija.

La aplicación móvil permite al cliente autenticarse mediante Google, consultar restaurantes, revisar menús y platos, realizar reservas, consultar sus reservas y cancelar aquellas que correspondan.

La aplicación web está orientada al administrador de restaurante y permite gestionar la información del establecimiento, horarios, imágenes, menús, platos, mesas y reservas.

**Sistema desplegado:** https://mesachapaca.netlify.app/  
**API:** https://mesachapaca-api.onrender.com/  
**Ruta de salud:** https://mesachapaca-api.onrender.com/api/v1/salud  
**APK:** https://github.com/LeonelVillca/Proyecto-Diplomado/releases/tag/v1.0.0

---

## 2. Stack tecnológico

| Componente | Versión o requisito | Función |
|---|---|---|
| Flutter | Dart SDK `^3.12.2` definido en `Frontend/pubspec.yaml` | Aplicación móvil y web |
| Dart | `^3.12.2` | Lenguaje del frontend |
| NestJS | `^11.0.1` | API y lógica de negocio |
| Node.js y npm | Versiones compatibles con NestJS 11; dependencias fijadas en `Backend/package-lock.json` | Ejecución y gestión del backend |
| TypeScript | `^5.7.3` | Lenguaje del backend |
| PostgreSQL | Versión compatible con las extensiones `btree_gist` y `pgcrypto` utilizadas por las migraciones | Base de datos |
| Firebase Authentication | Según las dependencias de Flutter y Firebase | Inicio de sesión del cliente mediante Google |
| Firebase Admin SDK | Según las dependencias del backend | Validación de identidad de Firebase en el servidor |
| JWT | Configuración del backend | Gestión de sesiones y acceso a rutas protegidas |
| Cloudinary y Cloudflare R2 | Servicios externos configurables | Almacenamiento de recursos |
| Brevo | API de correo transaccional | Envío de correos desde el backend |
| Socket.IO | Dependencias del backend | Comunicación en tiempo real relacionada con reservas |

---

## 3. Requisitos previos

- Git.
- Node.js y npm compatibles con NestJS 11.
- Flutter SDK con Dart `^3.12.2`.
- Herramientas correspondientes a la plataforma utilizada: Android SDK, Chrome u otra.
- PostgreSQL con una base de datos preparada para el esquema del proyecto.
- Credenciales locales para la base de datos.
- Un secreto JWT aleatorio.
- Firebase, Brevo y servicios de almacenamiento externo cuando se requiera probar dichas integraciones.

---

## 4. Instalación local

Clonar el repositorio:

```powershell
git clone https://github.com/LeonelVillca/Proyecto-Diplomado.git
cd Proyecto-Diplomado
```

### Backend

Ingresar al backend:

```powershell
cd Backend
npm ci
Copy-Item .env.example .env
```

Editar `Backend/.env` con los valores correspondientes al entorno local.

Como mínimo se deben configurar:

```text
DB_HOST
DB_PORT
DB_USER
DB_PASSWORD
DB_NAME
NODE_ENV
JWT_SECRET
CORS_ORIGINS
```

Para desarrollo:

```text
NODE_ENV=development
```

`JWT_SECRET` debe utilizar un valor aleatorio de al menos 32 caracteres. En producción se recomienda utilizar al menos 64 caracteres.

El archivo `.env` contiene información sensible y no debe publicarse ni versionarse.

El backend tiene `synchronize` desactivado y utiliza migraciones versionadas de forma incremental.

Las migraciones locales correspondientes pueden aplicarse desde `Backend/` mediante:

```powershell
node scripts/apply-security-migration.cjs --local-only
```

Iniciar el backend:

```powershell
npm run start:dev
```

La API queda disponible en:

```text
http://localhost:3000/api/v1
```

La documentación Swagger/OpenAPI se encuentra en:

```text
http://localhost:3000/docs
```

### Frontend

En otra terminal:

```powershell
cd Frontend
flutter pub get
```

Para ejecutar Flutter Web:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Para Android Emulator:

```text
--dart-define=API_BASE_URL=http://10.0.2.2:3000
```

En un dispositivo físico se debe utilizar una dirección IP de la computadora que pueda ser accedida desde el teléfono.

Las compilaciones de producción utilizan la URL HTTPS del backend mediante:

```text
--dart-define=API_BASE_URL=...
```

---

## 5. Variables de entorno

La plantilla de variables se encuentra en:

```text
Backend/.env.example
```

El archivo real `Backend/.env` es local y no debe versionarse.

| Variable | Obligatoria | Descripción |
|---|---|---|
| `NODE_ENV`, `PORT` | Sí | Entorno y puerto del backend |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Sí | Conexión a PostgreSQL |
| `DB_SSL` | En producción | Activa TLS para PostgreSQL |
| `DB_MIGRATION_USER`, `DB_MIGRATION_PASSWORD` | Cuando corresponda | Usuario utilizado para migraciones |
| `JWT_SECRET` | Sí | Clave utilizada para firmar tokens |
| `PIN_HMAC_SECRET` | En producción | Secreto independiente utilizado por los mecanismos correspondientes |
| `JWT_EXPIRES_IN` | No | Debe ser `1h` si se define |
| `CORS_ORIGINS` | En producción | Orígenes autorizados para consumir la API |
| `FRONTEND_URL`, `API_PUBLIC_URL` | En producción | URLs públicas del frontend y backend |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | Para Firebase | Credenciales de Firebase Admin |
| `BREVO_API_KEY`, `MAIL_FROM`, `MAIL_FROM_NAME` | Para correo | Configuración de Brevo |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Según almacenamiento | Configuración de Cloudinary |
| `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_ENDPOINT` | Según almacenamiento | Configuración de Cloudflare R2 |
| `ALLOW_DESTRUCTIVE_SEED`, `SEED_ADMIN_PASSWORD` | Solo desarrollo local | Control de datos de prueba |

No deben publicarse:

- archivos `.env`;
- credenciales de base de datos;
- claves privadas;
- API keys;
- tokens JWT;
- secretos utilizados en producción.

---

## 6. Estructura del repositorio

```text
.
├── Backend/
│   ├── migrations/
│   ├── reports/
│   ├── scripts/
│   ├── src/
│   ├── test/
│   ├── docs/
│   └── .env.example
│
├── Frontend/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── test/
│   ├── web/
│   └── windows/
│
├── Temporal/
└── README.md
```

---

## 7. Roles y credenciales de prueba

Para la revisión académica se utilizan cuentas ficticias.

| Rol | Usuario | Contraseña |
|---|---|---|
| Cliente | Se entrega por canal privado | Se entrega por canal privado |
| Administrador de restaurante | Se entrega por canal privado | Se entrega por canal privado |

Las credenciales de prueba se entregan únicamente mediante el mecanismo privado definido para la revisión.

No se publican contraseñas, tokens, credenciales de base de datos, claves de servicio ni contenido del archivo `.env` en este repositorio.

---

## 8. Pruebas

### Backend

Desde `Backend/`:

```bash
npm test
npm run test:e2e
npm run test:e3
```

### Frontend

Desde `Frontend/`:

```bash
flutter test
```

Las pruebas utilizadas para la evidencia E3 poseen reportes versionados dentro de:

```text
Backend/reports/
```

Entre los reportes disponibles se encuentran:

```text
Backend/reports/e3-summary.json
Backend/reports/e3-must-summary.json
Backend/reports/validacion-400-summary.json
Backend/reports/menor-privilegio-summary.json
Backend/reports/salud-summary.json
Backend/rnf01-summary.json
```

La suite E3 contempla pruebas relacionadas con:

- requisitos funcionales priorizados como Must;
- validación de datos;
- autenticación;
- autorización;
- respuestas HTTP 400;
- respuestas HTTP 401;
- respuestas HTTP 403;
- menor privilegio;
- comprobación de la ruta de salud.

La suite completa actual contiene 19 pruebas.

La suite original de requisitos Must contiene 14 pruebas y se conserva como evidencia independiente.

---

## 9. Despliegue

### Frontend web

La aplicación web se encuentra publicada en:

```text
https://mesachapaca.netlify.app/
```

### Backend

La API REST se encuentra publicada en:

```text
https://mesachapaca-api.onrender.com/
```

La ruta pública de salud es:

```text
https://mesachapaca-api.onrender.com/api/v1/salud
```

Cuando el backend y PostgreSQL se encuentran disponibles, la ruta responde HTTP 200 con:

```json
{
  "estado": "ok",
  "baseDatos": "conectada"
}
```

Si la conexión con PostgreSQL no se encuentra disponible, la ruta puede responder HTTP 503 con:

```json
{
  "estado": "error",
  "baseDatos": "no disponible"
}
```

### Aplicación Android

La versión instalable de Mesa Chapaca se encuentra publicada mediante GitHub Releases.

**Versión:**

```text
Mesa Chapaca v1.0.0
```

**Release:**

```text
https://github.com/LeonelVillca/Proyecto-Diplomado/releases/tag/v1.0.0
```

Para generar nuevamente el APK de producción:

```bash
cd Frontend
flutter build apk --release --dart-define=API_BASE_URL=https://mesachapaca-api.onrender.com
```

El archivo generado se encuentra en:

```text
Frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Configuración del entorno de producción

En Render se deben configurar las variables correspondientes al entorno publicado, incluyendo:

```text
NODE_ENV=production
DB_SSL=true
FRONTEND_URL=https://mesachapaca.netlify.app
API_PUBLIC_URL=https://mesachapaca-api.onrender.com
```

También deben configurarse los orígenes CORS, la conexión con PostgreSQL y los secretos necesarios para los servicios externos.

Antes de realizar un despliegue se recomienda:

- comprobar el estado de las migraciones;
- realizar una copia de seguridad de PostgreSQL;
- revisar las variables de producción;
- ejecutar las comprobaciones de producción.

Desde `Backend/`:

```bash
npm ci
npm run build
npm run preflight:prod
npm run start:prod
```

Para los bloqueos manuales por fecha y hora:

```bash
npm run migrate:mesa-bloqueos -- --apply
```

Si `DB_USER` es distinto del usuario utilizado para las migraciones:

```bash
npm run db:configure-runtime-role -- --apply
```

---

## 10. Licencia

Uso académico.

Todos los derechos reservados por el autor, salvo las dependencias y recursos de terceros, que mantienen sus respectivas licencias.

---

## 11. Verificación técnica y evidencias E3

### Ruta de salud

La ruta pública utilizada para comprobar el estado del backend es:

```text
GET https://mesachapaca-api.onrender.com/api/v1/salud
```

Esta ruta ejecuta una comprobación de PostgreSQL mediante el `DataSource` utilizado por la aplicación.

Cuando PostgreSQL responde correctamente:

```text
HTTP 200
```

```json
{
  "estado": "ok",
  "baseDatos": "conectada"
}
```

Cuando PostgreSQL no se encuentra disponible:

```text
HTTP 503
```

```json
{
  "estado": "error",
  "baseDatos": "no disponible"
}
```

La ruta es pública y permite verificar el estado del servicio desplegado.

### Suite automatizada E3

Desde `Backend/`:

```bash
npm run test:e3
```

La suite utiliza un entorno de pruebas separado de producción.

Para generar nuevamente los reportes:

```powershell
cd Backend
npm run build
npm run test:e3 -- --json --outputFile=.test-postgres-runtime/e3-results.json
node scripts/export-e3-report.cjs
```

### Reportes versionados

Las evidencias generadas se encuentran en:

```text
Backend/reports/e3-summary.json
Backend/reports/e3-must-summary.json
Backend/reports/validacion-400-summary.json
Backend/reports/menor-privilegio-summary.json
Backend/reports/salud-summary.json
Backend/rnf01-summary.json
```

La suite completa actual contiene 19 pruebas.

La suite original correspondiente a los requisitos Must contiene 14 pruebas.

Las pruebas adicionales verifican validación de datos, menor privilegio y estado de salud utilizando el entorno de prueba correspondiente.

### Verificación HTTP 403

Uno de los casos utilizados para verificar autorización corresponde a:

```text
GET /api/v1/usuarios
```

La solicitud utiliza un JWT válido perteneciente a un usuario con rol `admin_restaurante`.

La ruta requiere permisos correspondientes a `admin_sistema`, por lo que el backend responde:

```text
HTTP 403
```

Esta comprobación permite demostrar que la autorización se realiza en el servidor y no únicamente ocultando funcionalidades en el frontend.

Un cliente autenticado sin los permisos requeridos también debe recibir HTTP 403 al intentar acceder a una ruta no autorizada.

### Credenciales utilizadas para la revisión

Las cuentas creadas automáticamente durante las pruebas son temporales y no constituyen las credenciales entregadas al docente.

Para la revisión del sistema desplegado se deben verificar por separado:

- una cuenta ficticia de Cliente;
- una cuenta ficticia de Administrador de restaurante.

Las credenciales correspondientes se proporcionan únicamente por el canal privado definido para la entrega académica.

### Seguridad de las evidencias

Los reportes versionados no deben contener:

- contraseñas;
- tokens JWT;
- claves privadas;
- credenciales de PostgreSQL;
- secretos de Firebase;
- API keys;
- contenido del archivo `.env`.

El script de rendimiento requiere un `TOKEN` proporcionado durante la ejecución y no almacena un token real de forma predeterminada.