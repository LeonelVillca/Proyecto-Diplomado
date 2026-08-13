# GUÍA DE SEGUIMIENTO — Backend (NestJS + TypeORM + PostgreSQL)

## Contexto del sistema

Backend de una plataforma web y móvil de reservas y visibilidad de restaurantes en Tarija, Bolivia. Conecta a tres actores:

- **Cliente**: busca restaurantes, ve menús, hace reservas, deja reseñas y envía tickets de soporte (app móvil).
- **Administrador de Restaurante**: gestiona menú, mesas, horarios; responde reseñas, confirma/rechaza reservas y gestiona promociones (panel web).
- **Administrador de Sistema**: aprueba solicitudes de registro, gestiona usuarios y roles, modera reseñas y genera reportes generales (panel web).

Una persona puede tener varios roles a la vez (relación muchos-a-muchos entre usuarios y roles).

Stack técnico obligatorio:

- NestJS (Express por defecto)
- TypeORM
- PostgreSQL (base ya creada manualmente, 24 tablas; NO usar `synchronize: true`)
- Passport.js: estrategia local (correo/contraseña) + Google OAuth 2.0
- JWT para sesiones
- class-validator / class-transformer para DTOs
- WebSockets (Gateway nativo de NestJS) para reservas y disponibilidad de mesas en tiempo real

## Reglas de trabajo

1. Trabajo un solo módulo/tabla a la vez. No adelanto código de otro módulo, ni genero entidades de tablas que todavía no tocan según el orden definido.

2. Para cada módulo, entrego: `*.entity.ts`, los DTOs necesarios (`crear-*.dto.ts`, `actualizar-*.dto.ts`), `*.service.ts`, `*.controller.ts`, `*.module.ts`, y lo registro en `app.module.ts`.

3. Cada entidad debe usar los guards de rol (`@Roles(...)`) en los endpoints que correspondan, según qué actor puede hacer qué acción.

4. Al terminar un módulo, marco su casilla como completada en este archivo (`- [x]`), agrego cualquier nota relevante en "Notas y decisiones tomadas" y me detengo ahí.

5. No paso al siguiente módulo hasta que el usuario escriba explícitamente algo como "listo, continúa con el siguiente".

6. Si una tabla tiene relación con otra ya construida, uso esa relación real de TypeORM (`@ManyToOne`, `@OneToMany`, etc.), no la dejo como un simple número suelto.

7. Si noto algo raro o ambiguo en el modelo, pregunto antes de asumir. No invento columnas ni cambio el modelo sin avisar.

## Esquema de tablas (levantado de PostgreSQL `restaurantes_tarija`)

> Extraído directamente de la base con una consulta a `information_schema`. Es la fuente de verdad: **no inventar columnas**. TS indica tipo de dato (y largo donde aplica); PK = clave primaria; FK = relación real con su regla de borrado (`CASCADE`, `RESTRICT`, `SET NULL`). `synchronize` sigue en `false`.

### Tablas de identidad (01–05)

**usuarios** (PK `id_usuario`)
- `id_usuario` (int, PK, autoincremental → seq `usuarios_id_usuario_seq`)
- `nombre` (varchar(100)), `apellido` (varchar(100), nullable)
- `correo` (varchar(150), UNIQUE), `ci` (varchar(20), UNIQUE, nullable)
- `fecha_nacimiento` (date, nullable), `foto` (varchar(255), nullable), `telefono` (varchar(20), nullable)
- `estado` (varchar(20), default `'activo'`), `fecha_registro` (timestamp, default `now()`)

**rol** (PK `id_rol`)
- `id_rol` (int, PK, seq `rol_id_rol_seq`)
- `nombre` (varchar(50), UNIQUE), `descripcion` (varchar(255), nullable)

**permiso** (PK `id_permiso`)
- `id_permiso` (int, PK, seq `permiso_id_permiso_seq`)
- `codigo` (varchar(80), UNIQUE), `descripcion` (varchar(255), nullable)

**usuario_rol** (PK compuesta `id_usuario` + `id_rol`)
- `id_usuario` (int, PK+FK → `usuarios.id_usuario`, CASCADE)
- `id_rol` (int, PK+FK → `rol.id_rol`, RESTRICT)
- `fecha_asignacion` (timestamp, default `now()`)

**rol_permiso** (PK compuesta `id_rol` + `id_permiso`) — *módulo 05*
- `id_rol` (int, PK+FK → `rol.id_rol`, CASCADE)
- `id_permiso` (int, PK+FK → `permiso.id_permiso`, CASCADE)
- No tiene fecha. Simetría con `usuario_rol`: `@PrimaryColumn` + `@JoinColumn` sobre las mismas columnas.

### Autenticación (06–07)

**cuentas_auth** (PK `id_cuenta`)
- `id_cuenta` (int, PK, seq `cuentas_auth_id_cuenta_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE)
- `password_hash` (varchar(255), nullable), `ultimo_ingreso` (timestamp, nullable)
- `intentos_fallidos` (int, default `0`), `estado` (boolean, default `true`)

**oauth_cuenta** (PK `id_oauth`)
- `id_oauth` (int, PK, seq `oauth_cuenta_id_oauth_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE)
- `proveedor` (varchar(30)), `proveedor_id` (varchar(255)), `email_verificado` (boolean, default `false`)

### Registro de restaurantes (08–09)

**solicitud** (PK `id_solicitud`)
- `id_solicitud` (int, PK, seq `solicitud_id_solicitud_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE)
- `fecha` (date, default `CURRENT_DATE`), `estado` (varchar(20), default `'pendiente'`)
- `nombre_restaurante` (varchar(150)), `tipo_comida` (varchar(100), nullable), `nit_negocio` (varchar(30), nullable), `celular_contacto` (varchar(20), nullable), `descripcion` (text, nullable), `horarios_atencion` (varchar(255), nullable), `motivo_rechazo` (varchar(255), nullable)

**documento_adjunto** (PK `id_documento`)
- `id_documento` (int, PK, seq `documento_adjunto_id_documento_seq`)
- `id_solicitud` (FK → `solicitud.id_solicitud`, CASCADE)
- `tipo` (varchar(50)), `url` (varchar(255)), `fecha_carga` (timestamp, default `now()`)

### Restaurante y catálogo (10–16)

**restaurante** (PK `id_restaurante`)
- `id_restaurante` (int, PK, seq `restaurante_id_restaurante_seq`)
- `id_solicitud` (FK → `solicitud.id_solicitud`, SET NULL, nullable)
- `nombre` (varchar(150)), `tipo_comida` (varchar(100), nullable), `descripcion` (text, nullable), `telefono` (varchar(20), nullable), `correo` (varchar(150), nullable), `foto_portada` (varchar(255), nullable), `estado` (boolean, default `true`)

**ubicacion** (PK `id_ubicacion`)
- `id_ubicacion` (int, PK, seq `ubicacion_id_ubicacion_seq`)
- `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE)
- `direccion` (varchar(255), nullable), `latitud` (double precision, nullable), `longitud` (double precision, nullable)

**horario_atencion** (PK `id_horario`)
- `id_horario` (int, PK, seq `horario_atencion_id_horario_seq`)
- `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE)
- `dia_semana` (smallint), `hora_inicio` (time), `hora_fin` (time)

**mesa** (PK `id_mesa`)
- `id_mesa` (int, PK, seq `mesa_id_mesa_seq`)
- `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE)
- `numero_mesa` (varchar(20)), `capacidad` (int, nullable), `estado` (varchar(20), default `'libre'`)

**menu** (PK `id_menu`)
- `id_menu` (int, PK, seq `menu_id_menu_seq`)
- `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE)
- `nombre` (varchar(100)), `descripcion` (varchar(255), nullable), `tipo` (varchar(50), nullable), `disponibilidad` (boolean, default `true`)

**plato** (PK `id_plato`)
- `id_plato` (int, PK, seq `plato_id_plato_seq`)
- `id_menu` (FK → `menu.id_menu`, CASCADE)
- `nombre` (varchar(150)), `precio` (numeric, NO), `descripcion` (text, nullable), `disponible` (boolean, default `true`)

> Nota: `precio` es `numeric` sin precisión explícita; usar `type: 'numeric'` en TypeORM (no `decimal` con args inventados).

**imagen** (PK `id_imagen`)
- `id_imagen` (int, PK, seq `imagen_id_imagen_seq`)
- `id_plato` (FK → `plato.id_plato`, CASCADE, nullable) y `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE, nullable) — una imagen pertenece a un plato o a un restaurante
- `url` (varchar(255))

### Reservas, reseñas y soporte (17–21)

**reservas** (PK `id_reserva`) — *módulo con WebSocket*
- `id_reserva` (int, PK, seq `reservas_id_reserva_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE), `id_mesa` (FK → `mesa.id_mesa`, RESTRICT)
- `fecha` (date), `hora` (time), `numero_personas` (int), `estado` (varchar(20), default `'pendiente'`), `comentarios` (varchar(255), nullable), `fecha_creacion` (timestamp, default `now()`)

**resenas** (PK `id_resena`)
- `id_resena` (int, PK, seq `resenas_id_resena_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE), `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE)
- `comentario` (text, nullable), `calificacion` (smallint), `fecha` (timestamp, default `now()`)

**respuesta_resena** (PK `id_respuesta`)
- `id_respuesta` (int, PK, seq `respuesta_resena_id_respuesta_seq`)
- `id_resena` (FK → `resenas.id_resena`, CASCADE), `id_usuario_restaurante` (FK → `usuarios.id_usuario`, RESTRICT)
- `texto` (text), `fecha_respuesta` (timestamp, default `now()`)

**categoria_soporte** (PK `id_categoria`) — sin FKs
- `id_categoria` (int, PK, seq `categoria_soporte_id_categoria_seq`)
- `nombre` (varchar(100)), `descripcion` (varchar(255), nullable)

**soporte** (PK `id_soporte`)
- `id_soporte` (int, PK, seq `soporte_id_soporte_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE), `id_categoria_soporte` (FK → `categoria_soporte.id_categoria`, RESTRICT)
- `asunto` (varchar(150)), `descripcion` (text, nullable), `estado` (varchar(20), default `'pendiente'`), `respuesta` (text, nullable), `fecha_creacion` (timestamp, default `now()`), `fecha_respuesta` (timestamp, nullable)

### Reportes, notificaciones y visitas (22–24)

**reportes** (PK `id_reporte`)
- `id_reporte` (int, PK, seq `reportes_id_reporte_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE)
- `tipo` (varchar(50)), `fecha_inicio` (date, nullable), `fecha_fin` (date, nullable), `estado` (varchar(20), nullable), `fecha_creacion` (timestamp, default `now()`)

**notificacion** (PK `id_notificacion`)
- `id_notificacion` (int, PK, seq `notificacion_id_notificacion_seq`)
- `id_usuario` (FK → `usuarios.id_usuario`, CASCADE)
- `tipo` (varchar(30)), `mensaje` (text), `leido` (boolean, default `false`), `fecha_envio` (timestamp, default `now()`)

**visita** (PK `id_visita`)
- `id_visita` (int, PK, seq `visita_id_visita_seq`)
- `id_restaurante` (FK → `restaurante.id_restaurante`, CASCADE), `id_usuario` (FK → `usuarios.id_usuario`, SET NULL, nullable)
- `fecha_hora` (timestamp, default `now()`)

**vista_ranking_restaurantes** (vista existente en la BD) — no tiene PK ni FKs
- `id_restaurante` (int), `nombre` (varchar(150)), `calificacion_promedio` (numeric), `total_resenas` (bigint), `total_visitas` (bigint)

## Checklist de módulos

- [x] 01. usuarios — entidad, DTOs, service, controller, module
- [x] 02. rol — entidad, DTOs, service, controller, module
- [x] 03. permiso — entidad, DTOs, service, controller, module
- [x] 04. usuario_rol (tabla pivote: usuarios + rol) — entidad, DTOs, service, controller, module
- [x] 05. rol_permiso (tabla pivote: rol + permiso) — entidad, DTOs, service, controller, module
- [x] 06. cuentas_auth (login local: correo/contraseña) — entidad, DTOs, service, controller, module
- [x] 07. oauth_cuenta (login Google) + MÓDULO AUTH COMPLETO (LocalStrategy, GoogleStrategy, JwtStrategy, login/register/callback Google, emisión de JWT) — entidad, DTOs, service, controller, module
- [x] 08. solicitud — entidad, DTOs, service, controller, module
- [x] 09. documento_adjunto — entidad, DTOs, service, controller, module
- [x] 10. restaurante — entidad, DTOs, service, controller, module
- [x] 11. ubicacion — entidad, DTOs, service, controller, module
- [x] 12. horario_atencion — entidad, DTOs, service, controller, module
- [x] 13. mesa — entidad, DTOs, service, controller, module
- [x] 14. menu — entidad, DTOs, service, controller, module
- [x] 15. plato — entidad, DTOs, service, controller, module
- [x] 16. imagen — entidad, DTOs, service, controller, module
- [ ] 17. reservas (incluye Gateway de WebSocket) — entidad, DTOs, service, controller, module
- [ ] 18. resenas — entidad, DTOs, service, controller, module
- [ ] 19. respuesta_resena — entidad, DTOs, service, controller, module
- [x] 20. categoria_soporte — entidad, DTOs, service, controller, module
- [x] 21. soporte — entidad, DTOs, service, controller, module
- [x] 22. reportes — entidad, DTOs, service, controller, module
- [x] 23. notificacion — entidad, DTOs, service, controller, module
- [x] 24. visita — entidad, DTOs, service, controller, module

> Pendientes fuera de este ciclo: módulo de promoción (tabla aún no existe en la BD actual) y la vista `vista_ranking_restaurantes`, que **ya existe** en PostgreSQL y mapea 5 columnas (ver Esquema de tablas); se consumirá cuando corresponda su módulo.

## Notas y decisiones tomadas

- Módulo 01 (usuarios): la entidad mapea a la tabla `usuarios` con `synchronize: false` (ya se dejó `DB_SYNCHRONIZE=false` en `.env` y se fijó en `false` en `database.config.ts`). Endpoints CRUD básicos sin guards de rol, porque la infraestructura de autenticación y roles (JwtStrategy, RolesGuard, decoradores `@Roles`, `@Public`) se construye recién en el paso 07. Cuando exista, se aplican los guards a los endpoints que requieran `Admin_Sistema` (listar, asignar roles, gestionar estado/eliminar usuarios).
- Módulo 02 (rol): CRUD básico sobre `rol`. Las relaciones con `usuarios` y `permiso` (vía tablas pivote `usuario_rol` y `rol_permiso`) se agregarán con TypeORM recién cuando se construyan los módulos 04 y 05.
- Módulo 03 (permiso): CRUD básico sobre `permiso` (código UNIQUE). Relación con `rol` se agregará en el módulo 05.
- Módulo 04 (usuario_rol): pivote con PK compuesta (`id_usuario`, `id_rol`) y relaciones reales `@ManyToOne` con `Usuario` y `Rol`. Nota técnica: esta versión de TypeORM (1.1.0) no soporta la opción `primary` en `@ManyToOne`, por eso se declaró `@PrimaryColumn` + `@JoinColumn` sobre las mismas columnas. La app levantó y conectó con `restaurantes_tarija` (25 tablas + vista) sin errores.
- Módulo 05 (rol_permiso): pivote simétrico a `usuario_rol` con PK compuesta (`id_rol`, `id_permiso`) y relaciones reales `@ManyToOne` con `Rol` y `Permiso` (ambas `CASCADE`, igual que en el esquema). Usa el mismo patrón `@PrimaryColumn` + `@JoinColumn` (sin `primary` en `@ManyToOne`). Sin columna de fecha (el esquema no la tiene). Módulo `RolPermisoModule` registrado en `app.module.ts`. Endpoints: `POST /rol-permiso`, `GET /rol-permiso`, `GET /rol-permiso/rol/:idRol`, `GET /rol-permiso/permiso/:idPermiso`, `DELETE /rol-permiso/rol/:idRol/permiso/:idPermiso`. El servicio valida que existan `rol` y `permiso` (404 si no) y evita duplicados (idempotente). Probado: `npm run build` OK y arranque con `PORT=3001` conectó a `restaurantes_tarija` con `GET /api/v1/rol-permiso` → 200 `[]`. Las tablas `rol`, `permiso` y `rol_permiso` están vacías en la BD actual (no se insertó data de prueba). Sin guards de rol todavía (la infraestructura `@Roles`/`RolesGuard` no existe aún; se aplicará cuando se construya).
- Módulo 08 (solicitud): entidad `Solicitud` con FK real `@ManyToOne → usuarios` (CASCADE) y su columna correspondiente `id_usuario`. Campos mapeados exactos al esquema; `estado` tipado con `ESTADO_SOLICITUD = ['pendiente','aprobada','rechazada']` (mismo CHECK de la BD) y `fecha` con `default: () => 'CURRENT_DATE'` (la BD también lo tiene; no va en el DTO). `ActualizarSolicitudDto = OmitType(PartialType(CrearSolicitudDto), ['idUsuario'])` para no poder reasignar el dueño (evita el choque entre el DTO numérico `idUsuario` y la relación `usuario` al hacer `Object.assign`). Endpoints: `POST /solicitud`, `GET /solicitud`, `GET /solicitud/usuario/:idUsuario`, `GET /solicitud/:id`, `PATCH /solicitud/:id`, `DELETE /solicitud/:id`. El servicio valida que el `usuario` exista (404 si no). Probado sobre la BD real (PUERTO 3001): arranque OK, POST → 201 con `usuario` embebido y `estado='pendiente'`, GET por id OK, DELETE OK y `GET /solicitud` final `[]` (la fila de prueba se eliminó; la BD quedó limpia).
- BLOQUE ADMINISTRACIÓN (web): por decisión del usuario, se construyeron los módulos de administración (09-16 y 20-24) dejando los de reservas/reseñas (17-19) para el final, porque la parte móvil será solo de reservas y visualización y la web de administración.
- Módulo 09 (documento_adjunto): FK real a `solicitud` (CASCADE). Endpoints `POST/GET/GET :id/GET solicitud/:idSolicitud/PATCH/DELETE /documento-adjunto`.
- Módulo 10 (restaurante): FK real a `solicitud` (SET NULL, nullable). Endpoints CRUD `/restaurante`. En `crear`/`actualizar`, `idSolicitud` es opcional y se resuelve a la relación (se valida existencia si viene).
- Módulo 11 (ubicacion): FK real a `restaurante` (CASCADE). Ídem patrones; `latitud`/`longitud` como `double precision` con `@IsNumber`.
- Módulo 12 (horario_atencion): FK real a `restaurante` (CASCADE). `dia_semana` es `smallint` con validación 0-6 (mismo CHECK de la BD); `hora_inicio`/`hora_fin` tipo `time` con regex HH:MM[:SS].
- Módulo 13 (mesa): FK real a `restaurante` (CASCADE). `ESTADO_MESA = ['libre','ocupada','reservada','inactiva']` (mismo CHECK de la BD), default `libre`.
- Módulo 14 (menu): FK real a `restaurante` (CASCADE). `disponibilidad` boolean default `true`.
- Módulo 15 (plato): FK real a `menu` (CASCADE). `precio` tipo `numeric` (sin precisión inventada, como indica el esquema) con `transformer` para devolver `number` y CHECK `precio >= 0` replicado en el DTO con `@Min(0)`.
- Módulo 16 (imagen): FKs reales a `plato` y `restaurante` (ambas CASCADE, ambas nullable). El CHECK de la BD exige que la imagen pertenezca EXACTAMENTE a un plato O a un restaurante; se replicó con `BadRequestException` en `validarExclusividad` (crear y actualizar).
- Módulo 20 (categoria_soporte): sin FKs. CRUD simple `/categoria-soporte`.
- Módulo 21 (soporte): FKs reales a `usuarios` (CASCADE) y `categoria_soporte` (RESTRICT). `ESTADO_SOPORTE = ['pendiente','respondida']`. DECISIÓN: en `actualizar`, si se manda `respuesta` y no viene `estado`, se marca `respondida` y se sella `fecha_respuesta` automáticamente (igual si explícitamente se pasa `estado='respondida'` y aún no hay fecha).
- Módulo 22 (reportes): FK real a `usuarios` (CASCADE). `tipo` varchar(50); fechas opcionales con `@IsISO8601`; `estado` opcional varchar.
- Módulo 23 (notificacion): FK real a `usuarios` (CASCADE). Endpoint extra `PATCH /notificacion/:id/leer` para marcar leída.
- Módulo 24 (visita): FKs reales a `restaurante` (CASCADE) y `usuarios` (SET NULL, nullable — idUsuario opcional).
- VERIFICACIÓN BLOQUE ADMINISTRACIÓN: `npm run build` OK y arranque en `PORT=3001`; los 13 endpoints (`restaurante`, `documento-adjunto`, `ubicacion`, `horario-atencion`, `mesa`, `menu`, `plato`, `imagen`, `categoria-soporte`, `soporte`, `reportes`, `notificacion`, `visita`) respondieron 200 sin errores en stderr y sin insertar data (quedan vacías). Sin guards de rol todavía (la infraestructura `@Roles`/`RolesGuard` sigue pendiente).
- CONFIGURACIÓN BD: la clave real de PostgreSQL que funciona es `12345` (no `1234`, que es la que se indicó). Quedó seteado en `.env` (`DB_PASSWORD=12345`) y en el `database.config.ts`; `DB_NAME=restaurantes_tarija`.
- Módulo 06 (cuentas_auth): entidad `CuentaAuth` con FK real `@ManyToOne → usuários` (CASCADE). La columna `password_hash` es nullable (como en el esquema). El servicio expone `crear`, `asegurarCuenta` (crea la cuenta si el usuario aún no tiene y actualiza el hash si llega contraseña) y `registrarUltimoIngreso` (también resetea `intentos_fallidos`). Contraseñas con `bcryptjs`.
- Módulo 07 (oauth_cuenta + auth completo): entidad `OauthCuenta` con FK real a `usuarios`. El módulo `auth` incluye `POST /auth/login` (JSON `{ correo, password? }`), `POST /auth/register` (JSON `{ nombre, apellido?, correo, password? }`), `GET /auth/perfil` (protegido) y `JwtStrategy` + `JwtAuthGuard` (passport-jwt, secreto en `JWT_SECRET`). DECISIÓN: el login por correo hace auto-registro — si el correo no existe se crea el usuario con nombre derivado de la dirección (ej. `kevin.villca.herrera@gmail.com` → "Kevin Villca Herrera") y su fila en `cuentas_auth`. No se asigna rol automáticamente (eso toca permisos, módulo 04+05) y no se verifican contraseñas al hacer login sin password (campo opcional por ahora, se validará cuando se active LocalStrategy con contraseña obligatoria). PENDIENTE: `GoogleStrategy` + callback OAuth requiere credenciales de cliente Google (`GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET`); el frontend ya usa Firebase Google Sign-In y el módulo `oauth_cuenta` está listo para guardar el resultado. Probar `npm run build` y `POST /api/v1/auth/login`.

## Frontend (Flutter) — Login "Mesa Chapaca"

- Se implementó la pantalla de login en `lib/movil/` con arquitectura modular: `core/theme.dart` (paleta crema `#F6F4EE` + vino `#6B1A35`, fuente serif Playfair Display), `widgets/tarija_logo_header.dart`, `widgets/google_sign_in_button.dart` (logotipo oficial "G" dibujado con CustomPainter, sin asset externo), `providers/auth_provider.dart` (Firebase Auth + Google Sign-In con estados de carga) y `screens/login/login_screen.dart`.
- Firebase Auth conectado con `firebase_options.dart`; el flujo de Google usa la API de `google_sign_in` v7.2 (singleton `GoogleSignIn.instance`, `initialize()` y `authenticate()`).
- Fuentes Playfair Display descargadas a `assets/fonts/` y declaradas en `pubspec.yaml` junto con `assets/icon_app.jpg`.
- `lib/app.dart` monta `AuthScope` + `MaterialApp` con el tema propio; `lib/main.dart` inicializa Firebase antes de `runApp`.
- `flutter analyze` y `flutter test` pasan sin issues.
- INTEGRACIÓN FRONTEND–BACKEND (login por correo): `lib/movil/core/api_config.dart` centraliza la URL base (`http://localhost:3000`; en emulador Android usa `http://10.0.2.2:3000`; en teléfono físico se pasa con `--dart-define=API_BASE_URL=http://<ip-lan>:3000`). `AuthProvider.signInWithEmail(correo)` llama a `POST /api/v1/auth/login`, guarda `token` y el perfil (nombre/apellido/correo) y los expone en los getters `displayName`/`email` preferentemente sobre el perfil de Firebase. La tarjeta de login (`auth_bottom_card.dart`) ahora tiene el campo "Continuar con mi correo" (`http` agregado a `pubspec.yaml`). El saludo "¡Hola, Kevin! 👋" en `home_screen.dart` y la sección "Usuarios" en `profile_screen.dart` funcionan con los datos del backend sin cambios, porque ya consumen los getters del provider. Si el backend no está corriendo, el login por correo muestra el error (ya no cae al modo demo; el demo queda solo en el botón manual).
- LOGIN GOOGLE GUARDADO EN BD: `AuthProvider.signInWithGoogle()` tras entrar con Firebase llama a `POST /api/v1/auth/google` (DTO `GoogleLoginDto`), el cual crea/actualiza `usuarios`, vincula `oauth_cuenta` (proveedor `google`, `proveedor_id` = UID de Firebase, `email_verificado`) y registra `ultimo_ingreso` en `cuentas_auth`; devuelve JWT igual que el login local. Probado: usuario "Carla Ruiz" (id 3) quedó en `usuarios` + `oauth_cuenta` + `cuentas_auth`. Si el backend no responde, la sesión de Google se cierra y se muestra el error (sin caer a demo). Adicional: `AndroidManifest.xml` (main) tiene `INTERNET` + `usesCleartextTraffic` para permitir `http://` en Android 9+ durante pruebas.