# Mesa Chapaca

> Trabajo Final · Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026  
> Autor: Leonel Fernando Villca Ortega · Tutor: 

## 1. Descripción

Mesa Chapaca es un sistema web y móvil para descubrir y administrar restaurantes en Tarija. Permite consultar menús, horarios y ubicaciones, gestionar reservas y reseñas, y ofrece herramientas de administración para restaurantes y para la plataforma.

**Sistema desplegado:** [mesachapaca.netlify.app](https://mesachapaca.netlify.app/) · **API:** [mesachapaca-api.onrender.com](https://mesachapaca-api.onrender.com/) · **APK:** pendiente de generar y publicar

## 2. Stack tecnológico

| Componente | Versión o requisito | Función |
|---|---|---|
| Flutter | Dart SDK `^3.12.2` (definido en `Frontend/pubspec.yaml`) | Aplicación móvil y web |
| Dart | `^3.12.2` | Lenguaje del frontend |
| NestJS | `^11.0.1` | API y lógica de negocio |
| Node.js y npm | Versiones compatibles con NestJS 11; dependencias fijadas en `Backend/package-lock.json` | Ejecución y gestión del backend |
| TypeScript | `^5.7.3` | Lenguaje del backend |
| PostgreSQL | Versión compatible con las extensiones `btree_gist` y `pgcrypto` usadas por las migraciones | Base de datos |
| Firebase Authentication | Según las dependencias de Flutter y el SDK de Firebase Admin | Inicio de sesión con Google |
| Cloudinary y Cloudflare R2 | Servicios externos configurables | Imágenes y documentos |
| Brevo | API de correo transaccional | Verificación y notificaciones por correo |

## 3. Requisitos previos

- Git.
- Node.js y npm compatibles con NestJS 11.
- Flutter SDK con Dart `^3.12.2` y las herramientas de la plataforma que se vaya a ejecutar (Android, Chrome u otra).
- PostgreSQL con una base de datos preparada para el esquema del proyecto.
- Credenciales locales para la base de datos y un secreto JWT aleatorio.
- Firebase, Brevo y almacenamiento externo solo si se probarán esos servicios.

## 4. Instalación local

Clona el repositorio y configura el backend:

```powershell
git clone https://github.com/LeonelVillca/Proyecto-Diplomado.git
cd Proyecto-Diplomado/Backend
npm ci
Copy-Item .env.example .env
```

Edita `Backend/.env` con los datos de tu PostgreSQL. Configura como mínimo `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `NODE_ENV=development`, `JWT_SECRET` y `CORS_ORIGINS`. Genera `JWT_SECRET` con un valor aleatorio de al menos 32 caracteres; en producción usa al menos 64. No compartas ni subas el archivo `.env`.

El backend tiene `synchronize` desactivado y las migraciones versionadas son incrementales: no crean por sí solas el esquema inicial de una base vacía. Antes de arrancar por primera vez, prepara la base con el esquema inicial del proyecto. Para una base que ya tiene ese esquema, revisa primero los archivos de `Backend/migrations/` y el estado de la base; las migraciones locales se aplican explícitamente con `node scripts/apply-security-migration.cjs --local-only` desde `Backend`.

Inicia el backend:

```powershell
npm run start:dev
```

La API queda en `http://localhost:3000/api/v1` y la documentación Swagger en `http://localhost:3000/docs`.

En otra terminal, instala e inicia Flutter desde la raíz del proyecto:

```powershell
cd Frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Para Android Emulator usa `--dart-define=API_BASE_URL=http://10.0.2.2:3000`. En un teléfono físico, usa una dirección IP de la computadora que sea accesible desde el teléfono. Las compilaciones de producción requieren pasar una URL HTTPS mediante `--dart-define=API_BASE_URL=...`.

## 5. Variables de entorno

La plantilla completa está en [`Backend/.env.example`](Backend/.env.example). El archivo real `Backend/.env` es local y no debe versionarse.

| Variable | Obligatoria | Descripción |
|---|---|---|
| `NODE_ENV`, `PORT` | Sí | Entorno (`development`, `test` o `production`) y puerto del backend. |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Sí | Conexión a PostgreSQL. |
| `DB_SSL` | En producción | Activa TLS para PostgreSQL; debe ser `true` en producción. |
| `DB_MIGRATION_USER`, `DB_MIGRATION_PASSWORD` | Para migrar, si son distintos a `DB_USER` y `DB_PASSWORD` | Usuario con permisos DDL para las migraciones. |
| `JWT_SECRET` | Sí | Clave aleatoria para firmar tokens; mínimo 32 caracteres. |
| `PIN_HMAC_SECRET` | En producción | Clave aleatoria e independiente para proteger los PIN. En desarrollo puede derivarse del secreto JWT. |
| `JWT_EXPIRES_IN` | No | Debe ser `1h` si se define. |
| `CORS_ORIGINS` | En producción | Orígenes permitidos, separados por comas. En desarrollo también se permiten orígenes locales. |
| `FRONTEND_URL`, `API_PUBLIC_URL` | En producción | URLs HTTPS del frontend y del backend. `API_PUBLIC_URL` se usa en enlaces de verificación. |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | Para autenticación con Google y el preflight de producción | Credenciales de Firebase Admin. Mantén la clave privada fuera del repositorio. |
| `BREVO_API_KEY`, `MAIL_FROM`, `MAIL_FROM_NAME` | Para correo transaccional y el preflight de producción | API key y remitente usados por Brevo. |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Según el flujo de almacenamiento de imágenes | Credenciales de Cloudinary. |
| `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_ENDPOINT` | Según el flujo de documentos privados | Configuración de Cloudflare R2. |
| `ALLOW_DESTRUCTIVE_SEED`, `SEED_ADMIN_PASSWORD` | Solo para seed local explícito | Controla la carga destructiva de datos de prueba y su contraseña de administrador. No ejecutes el seed contra datos reales. |

## 6. Estructura del repositorio

```text
.
├── Backend/                 API NestJS, migraciones y archivos públicos
│   ├── migrations/          Migraciones SQL incrementales
│   ├── scripts/             Herramientas de migración y verificación
│   ├── src/                 Módulos y lógica del backend
│   └── storage/             Archivos públicos y documentos almacenados
├── Frontend/                Aplicación Flutter
│   ├── android/             Proyecto Android
│   ├── ios/                 Proyecto iOS
│   ├── lib/                  Código Dart de la aplicación
│   ├── test/                 Pruebas Flutter
│   ├── web/                  Aplicación web
│   └── windows/              Proyecto Windows
├── Temporal/                Archivos temporales de trabajo
└── README.md
```

## 7. Roles y credenciales de prueba

| Rol | Usuario | Contraseña |
|---|---|---|
| Administrador | Se entrega por canal privado | Se entrega por canal privado |
| Administrador de restaurante | Se entrega por canal privado | Se entrega por canal privado |
| Cliente | Se entrega por canal privado | Se entrega por canal privado |

Las credenciales de prueba se comunican a la coordinación por un canal privado. No se publican en este repositorio.

## 8. Pruebas

Backend, desde `Backend/`:

```bash
npm test
npm run test:e2e
npm run test:e3
```

Frontend, desde `Frontend/`:

```bash
flutter test
```

Las pruebas cubren componentes y flujos del backend y de Flutter. El alcance y los casos definitivos deben coincidir con la tabla de pruebas de la monografía.

## 9. Despliegue

El frontend está publicado en [https://mesachapaca.netlify.app/](https://mesachapaca.netlify.app/) y el backend en [https://mesachapaca-api.onrender.com/](https://mesachapaca-api.onrender.com/). En Render, configura `FRONTEND_URL=https://mesachapaca.netlify.app`, `API_PUBLIC_URL=https://mesachapaca-api.onrender.com` y agrega `https://mesachapaca.netlify.app` a `CORS_ORIGINS`.

El backend requiere PostgreSQL, variables de producción, conexión HTTPS y almacenamiento persistente para `Backend/storage` o la configuración del almacenamiento externo. Configura `NODE_ENV=production`, `DB_SSL=true`, secretos independientes y las credenciales de Firebase y Brevo requeridas por el preflight.

Antes de publicar, realiza una copia de seguridad de la base, revisa y aplica las migraciones pendientes, y sigue la guía de [Backend/docs/security-hardening.md](Backend/docs/security-hardening.md). Desde `Backend/`, los comandos previstos son:

Para los bloqueos manuales por fecha y hora, ejecuta `npm run migrate:mesa-bloqueos -- --apply` antes de desplegar el backend. Si `DB_USER` es distinto del usuario de migración, ejecuta después `npm run db:configure-runtime-role -- --apply` para conceder acceso a la tabla nueva. Publica también el frontend actualizado.

```bash
npm ci
npm run build
npm run preflight:prod
npm run start:prod
```

Compila Flutter con la URL del backend de Render. Esta URL se incluye en la aplicación y es la que usará la APK para comunicarse con la API:

```bash
cd Frontend
flutter build apk --release --dart-define=API_BASE_URL=https://mesachapaca-api.onrender.com
```

El APK de lanzamiento se genera en `Frontend/build/app/outputs/flutter-apk/app-release.apk`. Publica ese archivo en el canal de entrega acordado y agrega aquí el enlace de descarga cuando esté disponible. El manual de instalación y despliegue de la monografía debe documentar los valores y pasos concretos del entorno publicado.

## 10. Licencia

Uso académico. Todos los derechos reservados por el autor, salvo las dependencias de terceros y sus respectivas licencias.

## 11. Verificación técnica y evidencias E3

Ruta de salud: [GET /api/v1/salud](https://mesachapaca-api.onrender.com/api/v1/salud).
Ejecuta `SELECT 1` mediante el DataSource existente. Devuelve HTTP 200 con
`{"estado":"ok","baseDatos":"conectada"}` si PostgreSQL responde y HTTP 503 con
`{"estado":"error","baseDatos":"no disponible"}` si la consulta falla. Es pública.
Su disponibilidad en producción debe verificarse después de desplegar.

Desde `Backend`, `npm run test:e3` utiliza PostgreSQL 16 local, puerto 55433 y
la base exclusiva `mesa_chapaca_e3_test`; no carga `.env` ni utiliza producción.
Si corresponde, define `E3_PG_BIN` con la carpeta de ejecutables PostgreSQL.
Consulta [el alcance de las pruebas E3](Backend/test/e3/README.md).

Para generar los reportes de una nueva ejecución:

```powershell
cd Backend
npm run build
npm run test:e3 -- --json --outputFile=.test-postgres-runtime/e3-results.json
node scripts/export-e3-report.cjs
```

Evidencias sin logs, tokens ni credenciales, preparadas para versionarse:

- [Resumen E3](Backend/reports/e3-summary.json).
- [Suite original de 14 pruebas](Backend/reports/e3-must-summary.json).
- [Validación 400](Backend/reports/validacion-400-summary.json).
- [Menor privilegio y 403](Backend/reports/menor-privilegio-summary.json).
- [Salud con PostgreSQL real](Backend/reports/salud-summary.json).
- [Resumen RNF-01 existente](Backend/rnf01-summary.json).

La suite completa actual contiene 19 pruebas. La suite original sustituye la
verificación externa de Firebase; las pruebas de validación y menor privilegio
no usan mocks. Menor privilegio verifica los servicios compartidos de creación,
pero no ejecuta Google externo. Estos resultados corresponden al entorno local.

Caso 403: `GET /api/v1/usuarios` con un JWT válido de `admin_restaurante`.
La ruta exige `admin_sistema` mediante `RolesGuard` y responde HTTP 403.
Un cliente autenticado sin roles también recibe 403.

Las cuentas de los tests son temporales y no constituyen credenciales de entrega.
Antes de entregar, verifica por separado una cuenta cliente ficticia y una de
administrador de restaurante, sus accesos y su vínculo de restaurante. Entrega
sus credenciales por canal privado, con contraseñas de al menos 10 caracteres.
El archivo local de credenciales históricas no demuestra que sigan funcionando.

El script de rendimiento requiere `TOKEN` suministrado al proceso; no incorpora
un token predeterminado. No publiques tokens ni ejecutes carga contra producción
sin autorización.