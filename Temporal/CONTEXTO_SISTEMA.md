# CONTEXTO_SISTEMA.md — Mesa Chapaca

> **Punto de entrada para entender el sistema completo.** Si retomas este
> proyecto en una sesión nueva, lee este archivo primero. Para el detalle
> módulo por módulo (DTOs, endpoints, notas técnicas) usa
> [`Backend/GUIA_SEGUIMIENTO.md`](./Backend/GUIA_SEGUIMIENTO.md), que sigue
> siendo la fuente de verdad del detalle.

---

## 1. Qué es el sistema

Plataforma de **reservas y visibilidad de restaurantes en Tarija, Bolivia**
("Mesa Chapaca"). Conecta a tres actores, y una persona puede tener varios
roles a la vez (relación muchos-a-muchos entre usuarios y roles):

- **Cliente**: busca restaurantes, ve menús, hace reservas, deja reseñas y
  envía tickets de soporte → app **móvil** (Flutter).
- **Admin_Restaurante**: gestiona menú, mesas y horarios; confirma/rechaza
  reservas, responde reseñas y gestiona promociones → **web**.
- **Admin_Sistema**: aprueba solicitudes de registro, gestiona usuarios y
  roles, modera reseñas y genera reportes → **web**.

## 2. Stack técnico completo

| Capa | Tecnología |
| --- | --- |
| Backend | NestJS + TypeORM + PostgreSQL (base `restaurantes_tarija`, **25 tablas + 1 vista**, `synchronize: false`) |
| Frontend | Flutter en **un solo proyecto** con split interno `lib/movil/` (app Cliente) y `lib/admin/` (futuro panel web); la decisión de plataforma se toma con `kIsWeb` |
| Autenticación | **Exclusivamente Google OAuth**. El frontend obtiene el ID Token de Firebase y el backend lo verifica **server-side** con `firebase-admin` antes de emitir su propio JWT |
| Sesión | JWT propio del backend (Passport `passport-jwt`), guardado en el móvil con `flutter_secure_storage` (Keystore/Keychain) |
| HTTP | `http` en Flutter; URLs centralizadas en `lib/core/network/api_endpoints.dart` |
| Tiempo real | WebSocket (Gateway nativo de NestJS) para el módulo de reservas (pendiente de construir) |

## 3. Decisiones de seguridad tomadas

- **13/08/2026 — Eliminado el login por correo sin verificación.** El flujo
  de "correo suelto sin contraseña" (`POST /auth/login`, auto-registro con
  solo un email) permitía suplantar a cualquier usuario escribiendo su
  correo, sin ninguna verificación de identidad. Se eliminó por completo
  (endpoint y método de servicio), igual que su botón/campo en el frontend.
- **13/08/2026 — Toda autenticación pasa por Google, verificada
  server-side.** El frontend autentica con Firebase/Google y envía el ID
  Token al backend (`POST /auth/google` → body `{ idToken }`). El backend lo
  valida con `firebase-admin` (`verifyIdToken`) y **solo si es válido**
  crea/actualiza `usuarios`, vincula `oauth_cuenta` (`proveedor='google'`,
  `proveedor_id = decodedToken.uid`), registra `ultimo_ingreso` y emite el
  JWT propio. Nunca confía en correo/nombre/UID que venga en el body sin
  verificar. Token inválido/expirado → **401 Unauthorized** sin tocar la BD.
- **El JWT propio se guarda en storage seguro** (`flutter_secure_storage`),
  no en `shared_preferences` ni en variables de memoria; al abrir la app se
  valida contra `GET /auth/perfil` y ante 401 se limpia la sesión.
- **19/08/2026 — Arquitectura de Almacenamiento (público vs privado)**. La
  gestión de archivos en disco se organiza estrictamente por ID de entidad.
  Existe separación absoluta: `storage/publico/` (servido estáticamente, para
  fotos/menús) y `storage/privado/` (NUNCA estático, acceso por Controller+Guard,
  para CI/NIT). Los nombres de archivos se renuevan siempre por UUID.
- **19/08/2026 — Autoservicio de acceso Admin**. El login del panel Admin ya
  no depende de que el Admin_Sistema cree contraseñas manualmente. Ahora es
  autoservicio vía invitación (creación de contraseña con token en tabla
  `invitacion_token`).

## 4. Estado actual del backend

- **Construidos (21 módulos, responden 200)**: identidad (usuarios, rol,
  permiso, usuario_rol, rol_permiso), autenticación (cuentas_auth,
  oauth_cuenta + módulo `auth` con JWT), registro de restaurantes (solicitud,
  documento_adjunto), restaurante y catálogo (restaurante, ubicacion,
  horario_atencion, mesa, menu, plato, imagen), soporte (categoria_soporte,
  soporte), reportes/notificaciones/visitas (reportes, notificacion, visita).
- **Pendientes**: 17 `reservas` (con WebSocket), 18 `resenas`,
  19 `respuesta_resena`, módulo de **promoción** (tabla aún no existe en la
  BD) y el consumo de la vista `vista_ranking_restaurantes` (ya existe en
  PostgreSQL, 5 columnas).
- Detalle completo (esquema, DTOs, endpoints, decisiones por módulo) en
  [`Backend/GUIA_SEGUIMIENTO.md`](./Backend/GUIA_SEGUIMIENTO.md).

## 5. Estado actual del frontend (Flutter)

- **Conectado al backend real**: login con Google (`POST /auth/google` con
  ID Token → JWT propio), restauración de sesión (`GET /auth/perfil`), y el
  perfil/saludo del home alimentados por el backend. El JWT vive en
  `SessionService` (`flutter_secure_storage`).
- **UI con datos demo (mock) pendiente de conectar a la API**: catálogo de
  restaurantes (`lib/movil/data/restaurantes_mock.dart` + `models/restaurant.dart`)
  y el módulo de Reservas (Próximas/Historial, `reservations_screen.dart`).
- Navegación de 5 pestañas (Inicio, Reservas, Favoritos, Ubicación, Usuarios)
  con `IndexedStack`; favoritos en memoria (`FavoritesStore`).

## 6. Cómo correr el proyecto en desarrollo

### Backend (NestJS, en `Backend/`)

```bash
npm install
npm run start:dev        # arranca en http://localhost:3000, prefijo /api/v1
```

Variables de entorno necesarias (`.env`, valores reales NO se commitean;
ver `.env.example`):

```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=<password de PostgreSQL>
DB_NAME=restaurantes_tarija
DB_SYNCHRONIZE=false
JWT_SECRET=<secreto largo>
JWT_EXPIRES_IN=7d
# Firebase Admin (cuenta de servicio de Firebase). OBLIGATORIAS para que
# /auth/google verifique tokens; sin ellas responde 401.
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=   # pegar con saltos de línea escapados como \n
```

### Frontend (Flutter, en `Frontend/`)

```bash
flutter pub get
flutter run              # emulador/Android → usa 10.0.2.2 (Environment.emulador)
flutter run -d chrome    # web → usa localhost
```

Para probar desde un **dispositivo físico** (misma red WiFi), cambiar
`currentEnv` en `lib/core/network/api_endpoints.dart` a
`Environment.dispositivoFisico` y poner la IP LAN de la PC. El backend
escucha en `0.0.0.0` y CORS abierto para desarrollo.

### Pruebas

```bash
# Backend
npm run build && npm test && npm run lint
# Frontend
flutter analyze && flutter test
```
