# GUÍA DE SEGUIMIENTO — Backend (NestJS + TypeORM + PostgreSQL)

> **Punto de entrada para entender el sistema completo:**
> [`../CONTEXTO_SISTEMA.md`](../CONTEXTO_SISTEMA.md). Este archivo es la
> fuente de verdad del detalle módulo por módulo; el contexto resume el
> sistema de arriba hacia abajo.

## Contexto del sistema

Backend de una plataforma web y móvil de reservas y visibilidad de restaurantes en Tarija, Bolivia. Conecta a tres actores:

- **Cliente**: busca restaurantes, ve menús, hace reservas, deja reseñas y envía tickets de soporte (app móvil).
- **Administrador de Restaurante**: gestiona menú, mesas, horarios; responde reseñas, confirma/rechaza reservas y gestiona promociones (panel web).
- **Administrador de Sistema**: aprueba solicitudes de registro, gestiona usuarios y roles, modera reseñas y genera reportes generales (panel web).

Una persona puede tener varios roles a la vez (relación muchos-a-muchos entre usuarios y roles).

## Resumen de avance

- **Backend (NestJS)**: terminados los módulos 01–16 y 20–24 (identidad, autenticación, registro de restaurantes, catálogo y administración web). Pendientes: 17 reservas (con WebSocket), 18 resenas, 19 respuesta_resena (bloque móvil/reservas, se hace al final por decisión del usuario), además del módulo de promoción (tabla inexistente) y la vista `vista_ranking_restaurantes`.
- **Frontend (Flutter)**: login exclusivamente con Google (ID Token verificado server-side) conectado al backend (JWT), navegación con 5 pestañas y UI de Reservas (Próximas/Historial) con datos demo pendiente de conectar a la API.
- **Base de datos**: `restaurantes_tarija` con 25 tablas + vista, `synchronize: false`; los 21 módulos construidos del esquema (01–16 y 20–24) levantan y responden 200 sin crear data.

Stack técnico obligatorio:

- NestJS (Express por defecto)
- TypeORM
- PostgreSQL (base ya creada manualmente, 24 tablas; NO usar `synchronize: true`)
- Passport.js: estrategia JWT para sesiones
- JWT para sesiones
- Autenticación exclusivamente vía Google OAuth (verificado con `firebase-admin`)
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
- [x] 07. oauth_cuenta (login Google) + MÓDULO AUTH COMPLETO (JwtStrategy, `POST /auth/google` verificado con `firebase-admin`, `POST /auth/register`, `GET /auth/perfil`, emisión de JWT) — entidad, DTOs, service, controller, module
- [x] 08. solicitud — entidad, DTOs, service, controller, module
- [x] 09. documento_adjunto — entidad, DTOs, service, controller, module
- [x] 10. restaurante — entidad, DTOs, service, controller, module
- [x] 11. ubicacion — entidad, DTOs, service, controller, module
- [x] 12. horario_atencion — entidad, DTOs, service, controller, module
- [x] 13. mesa — entidad, DTOs, service, controller, module
- [x] 14. menu — entidad, DTOs, service, controller, module
- [x] 15. plato — entidad, DTOs, service, controller, module
- [x] 16. imagen — entidad, DTOs, service, controller, module
- [x] 17. reservas (incluye Gateway de WebSocket) — entidad, DTOs, service, controller, module
- [x] 18. resenas — entidad, DTOs, service, controller, module
- [x] 19. respuesta_resena — entidad, DTOs, service, controller, module
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
- Módulo 07 (oauth_cuenta + auth completo): entidad `OauthCuenta` con FK real a `usuarios`. El módulo `auth` incluye `POST /auth/google` (JSON `{ idToken }`, verifica con `firebase-admin`), `POST /auth/register`, `GET /auth/perfil` (protegido) y `JwtStrategy` + `JwtAuthGuard` (passport-jwt, secreto en `JWT_SECRET`). No se asigna rol automáticamente (eso toca permisos, módulo 04+05).
- DECISIÓN DE SEGURIDAD (13/08/2026) — AUTENTICACIÓN EXCLUSIVAMENTE CON GOOGLE: se eliminó el flujo de "correo suelto sin contraseña" por ser vulnerable a suplantación (cualquiera podía iniciar sesión escribiendo un correo, sin verificación real de identidad). Se borraron el endpoint `POST /auth/login`, el método `AuthService.login()`, el DTO `login.dto.ts`, el método `AuthProvider.signInWithEmail` y el campo/botón "Continuar con mi correo" del frontend. Ahora `POST /auth/google` recibe solo `{ idToken }` y el backend lo verifica server-side con `firebase-admin` (`verifyIdToken`, servicio `FirebaseAdminService` en `src/modules/auth/`); solo si la verificación es exitosa se crea/actualiza `usuarios`, se vincula `oauth_cuenta` (`proveedor='google'`, `proveedor_id = decodedToken.uid`) y se emite el JWT propio. Token inválido/expirado → 401 sin tocar la BD. Credenciales de la cuenta de servicio de Firebase en `.env`/`.env.example` (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`); sin ellas `/auth/google` responde 401 hasta configurarlas. En el frontend el JWT se persiste con `flutter_secure_storage` vía `core/services/session_service.dart` y al abrir la app se valida contra `GET /auth/perfil` (401 → limpiar storage y volver al login). Probado: `npm run build` OK, `npm test` OK, `POST /auth/google` con token inválido → 401, `POST /auth/login` → 404. Ver [`../CONTEXTO_SISTEMA.md`](../CONTEXTO_SISTEMA.md).
- FASE A (TAREA A1): Se creó la infraestructura base de seguridad y autorización en `src/core/`. Se agregó el decorador `@Roles(...)` y `RolesGuard` para restringir acceso por el rol del usuario (extraído desde `usuario_rol` consultado en base de datos), y el `OwnershipGuard` para asegurar que un `Admin_Restaurante` solo modifique recursos (restaurante, menú, mesas, etc.) pertenecientes a sus propios restaurantes aprobados. Las reglas aún no se han inyectado en los controladores. Todo compila correctamente sin romper código existente.
- FASE A (TAREA A2): Se aplicó el decorador `@Roles('admin_sistema')` y los guardias de autenticación JWT + Roles a los controladores del Administrador del Sistema: `roles`, `permisos`, `categoria-soporte` y `reportes` (protegidos globalmente) y endpoints específicos de `usuarios` (listar/actualizar/eliminar) y `solicitud` (listar/actualizar/eliminar).
- FASE A (TAREA A3): Se aplicaron `@Roles('admin_restaurante', 'admin_sistema')` y el `@CheckOwnership(...)` a los endpoints de escritura (`POST`, `PATCH`, `DELETE`) de los controladores `restaurante`, `menu`, `plato`, `imagen`, `mesa` y `horario-atencion`. Los endpoints de lectura (`GET`) quedan protegidos solo por JWT para que clientes autenticados puedan ver el catálogo. Todo compila sin errores.
- FASE A (TAREA A4): Se construyó el `ClientOwnershipGuard` para garantizar que un Cliente solo pueda interactuar con sus propios tickets de `soporte` y `notificacion` (al consultar listados, ver detalle o crear). Se aplicó a los endpoints relevantes de ambos módulos, mientras que las operaciones administrativas de los mismos quedaron blindadas con `@Roles('admin_sistema')`. (Las reservas y reseñas se protegerán cuando se construyan en la Fase B).
- FASE B (TAREA B1 - Módulo 17): Se creó el módulo de `reservas`. La entidad `Reserva` incluye FK a `Usuario` (CASCADE) y `Mesa` (RESTRICT), tal como indica el esquema. Se instaló `@nestjs/websockets` y `@nestjs/platform-socket.io` y se creó `ReservasGateway` para emitir eventos de `nueva_reserva` y `reserva_actualizada`. Se aplicó la seguridad de forma nativa: clientes solo pueden crear para sí mismos, y el `Admin_Restaurante` puede ver, aprobar o rechazar usando el `OwnershipGuard` (que se actualizó para soportar de forma dinámica el recurso `'reserva'`). Módulo registrado en `app.module.ts` y compila correctamente sin errores.
- FASE B (TAREA B2 - Módulo 18): Se creó el módulo de `resenas`. La entidad `Resena` incluye FK a `Usuario` (CASCADE) y `Restaurante` (CASCADE). En cuanto a seguridad, se amplió el `ClientOwnershipGuard` para soportar el recurso `'resena'`, garantizando que un Cliente solo pueda crear o borrar **sus propias** reseñas. El `admin_sistema` mantiene permisos globales. Los clientes pueden leer libremente todas las reseñas de un restaurante (`GET /restaurante/:idRestaurante`). Módulo registrado y compila correctamente.
- FASE B (TAREA B3 - Módulo 19): Se creó el módulo de `respuesta-resena`. La entidad tiene FK a `Resena` (CASCADE) y a `Usuario` (RESTRICT) para el autor de la respuesta. Se aplicó el decorador `@CheckOwnership('resena')` para que el `OwnershipGuard` valide que el `admin_restaurante` que intenta responder es realmente el dueño del restaurante al que pertenece la reseña original. Módulo registrado y compilando perfectamente.
- DECISIÓN DEL USUARIO (14/08/2026): Las Tareas B4 (Promociones), B5 (Ranking) y la Fase C (Conectar app móvil a API) se postergan por ahora. El desarrollo salta directamente a la **FASE D (Panel Web Administrativo)** en el frontend (`lib/admin/`).
- FASE D (TAREA D1): Se construyó la `Landing pública` (`AdminLandingScreen`) en `lib/admin/screens/`. Se usó `kIsWeb` en `app.dart` para enrutar a esta pantalla solo si el usuario abre la aplicación desde un navegador de escritorio (dejando intacta la app móvil para Android/iOS). Se aplicó un diseño premium (vibrante, moderno) con `LandingNavbar`, `LandingHero` y `LandingBenefits`.
- FASE D (TAREA D2): Se creó `SolicitudRegistroScreen`, un formulario público para que los dueños de restaurantes soliciten unirse. Se modificó el backend (`POST /solicitud`) para que sea `@Public()` (removiendo el AuthGuard a nivel clase y poniéndolo a nivel método) y se adaptó `CrearSolicitudDto` para recibir `nombreUsuario`, `apellidoUsuario` y `correoUsuario` en lugar del ID, de modo que el servicio cree la cuenta automáticamente si el correo no existe. El formulario en Flutter se conecta exitosamente a este endpoint y navega de regreso a la landing al enviar con éxito.
- FASE D (TAREA D3): Se construyó `AdminLoginScreen` con un diseño de doble panel usando la imagen de fondo de Tarija. Como el usuario había decidido eliminar el login por correo del backend para la parte móvil (dejando solo Google), se **restauró el endpoint `POST /auth/login`** exclusivamente para este flujo web administrativo, validando la contraseña contra `CuentaAuth`. La app en Flutter ahora envía correo/contraseña, recibe el JWT y lo guarda exitosamente en el storage seguro utilizando `AuthProvider`.
- FASE D (TAREA D4): Se implementó el enrutamiento post-login por rol. Para esto se modificó `auth.service.ts` en el backend para que `GET /auth/perfil` también devuelva el arreglo de roles del usuario (extraído desde `UsuarioRol`). Luego, en el frontend, `AuthProvider` parsea los roles, y el `AdminLoginScreen` verifica `hasRole(...)`: si es `admin_sistema` lo manda al `AdminSistemaDashboard`, si es `admin_restaurante` al `AdminRestauranteDashboard`, y si no tiene ninguno le muestra un cuadro de diálogo de "Acceso Denegado" y cierra la sesión. Se prepararon las vistas base para ambas fases (E y F).
- FASE E (TAREA E1): Se creó el layout principal `AdminSistemaDashboard` con un Sidebar minimalista y Navbar superior (diseño limpio y profesional). Se implementó `SolicitudesScreen` donde el administrador puede listar las peticiones (filtradas por pendiente, aprobada, rechazada), ver el detalle de los datos enviados en el formulario, y aprobar o rechazar consumiendo los endpoints del backend que fueron ajustados para soportar filtrado de estados por consulta (`?estado=X`).
- FASE E (TAREA E2): Se construyó la pantalla `UsuariosRolesScreen`, que lista a todos los usuarios del sistema (consumiendo `GET /usuarios`). Mediante un botón "Editar Roles", se despliega un modal dinámico con checkboxes que carga los roles disponibles (`GET /roles`) y pre-selecciona los que el usuario ya tiene asignados (`GET /usuario-rol/usuario/:id`). Al guardar, se sincronizan agregando (`POST`) o quitando (`DELETE`) las asignaciones específicas de roles al usuario.
- FASE E (TAREA E3): Se implementó la `ModeracionScreen` para revisar todas las reseñas de la plataforma. Consume `GET /resenas` (protegido por `@Roles('admin_sistema')`) y muestra una lista con la calificación (estrellas visuales), el texto, el restaurante y el autor. Permite eliminar reseñas inapropiadas consumiendo `DELETE /resenas/:id` (el `ClientOwnershipGuard` fue configurado para permitir que `admin_sistema` evada la restricción de dueño).
- FASE F (TAREA F1): Se construyó el `AdminRestauranteDashboard` (layout análogo pero con opciones orientadas a la sucursal). Se implementó `PerfilRestauranteScreen` y, del lado backend, se creó el endpoint `GET /restaurante/mis-restaurantes` en `restaurante.controller.ts` para que el `admin_restaurante` pueda recuperar su restaurante automáticamente según el JWT enviado, modificando sus campos públicos como tipo de comida, contacto y descripción.
- FASE F (TAREA F2): Se construyó la pantalla `GestionMesasScreen` donde el dueño del restaurante puede visualizar las mesas asignadas a su restaurante (`GET /mesa/restaurante/:id`). Se implementó un modal de creación y edición (con validaciones de capacidad y ubicación en dropdown) que interactúa con `POST /mesa` y `PATCH /mesa/:id`. Por último, la opción de eliminar mesa (`DELETE /mesa/:id`).
- FASE F (TAREA F3): Se construyó la pantalla `GestionMenusScreen`. Incluye una vista principal para listar los menús (`GET /menu/restaurante/:id`) junto con el conteo de sus platillos iterando sobre `GET /plato/menu/:id`. Al hacer clic en "Crear Menú", se alterna a un formulario limpio (dentro de la misma vista para mantener el sidebar) que permite agregar el nombre del menú, tipo (dropdown), y añadir dinámicamente múltiples platillos al mismo tiempo pulsando "+ Agregar Platillo". Al guardar, ejecuta de forma asíncrona un `POST /menu` seguido de varios `POST /plato` para cada ítem, resolviendo todo en un solo flujo visual sin necesidad de endpoints transaccionales anidados.
- FASE F (TAREA F4): Omitida temporalmente por la decisión del usuario (14/08/2026) de posponer el módulo de Promociones en el backend (Tarea B4).
- FASE F (TAREA F5): Se construyó la pantalla `GestionReservasScreen`. Se listan todas las reservas del restaurante (`GET /reservas/restaurante/:id`) y se consumió la librería `socket_io_client` para conectar el frontend con el `ReservasGateway` del backend (usando `auth.token`). La pantalla escucha los eventos `nueva_reserva` y `reserva_actualizada` para lanzar un SnackBar y refrescar el listado automáticamente en tiempo real sin recargar la página. Permite Confirmar o Rechazar reservas en estado "pendiente" (vía `PATCH /reservas/:id`).
- FASE F (TAREA F6): Se construyó la pantalla `GestionResenasScreen`. Se muestran todas las reseñas recibidas del restaurante (`GET /resenas/restaurante/:id`) junto con la calificación (estrellas) y el comentario. Internamente, itera para cargar las respuestas dadas (`GET /respuesta-resena/resena/:id`). Permite al administrador responder a la reseña abriendo un modal que invoca a `POST /respuesta-resena` o `PATCH /respuesta-resena/:id` según corresponda. Todo manejado de forma asíncrona.
- FASE F (TAREA F7): Se construyeron las pantallas `SoporteRestauranteScreen` y `ReportesRestauranteScreen`. Para Soporte, el dueño puede visualizar sus tickets (`GET /soporte/usuario/:id`) y crear nuevos (`POST /soporte`) seleccionando una categoría. Para Reportes, se incorporó una vista de cuadrícula con estadísticas clave de reservas (pendientes/confirmadas), reseñas (promedio de calificación) y total de visitas del restaurante. Se modificó el `AdminRestauranteDashboard` para incluir la opción "Reportes" en el sidebar, completando así la Fase F del administrador de restaurantes.

## Frontend (Flutter) — App móvil "Mesa Chapaca"

### Login y autenticación

- Pantalla de login en `lib/movil/` con arquitectura modular: `core/theme.dart` (paleta crema `#F6F4EE` + vino `#6B1A35`), `widgets/auth_bottom_card.dart` (única acción: "Continuar con Google"), `widgets/google_sign_in_button.dart` (logotipo oficial "G" dibujado con CustomPainter, sin asset externo), `providers/auth_provider.dart` (Firebase Auth + Google Sign-In con estados de carga) y `screens/login/login_screen.dart`.
- Firebase Auth conectado con `firebase_options.dart`; el flujo de Google usa la API de `google_sign_in` v7.2 (singleton `GoogleSignIn.instance`, `initialize()` y `authenticate()`).
- `lib/main.dart` inicializa Firebase antes de `runApp`; `lib/app.dart` monta `AuthScope` + `FavoritesScope` + `MaterialApp` con el tema propio.
- `flutter analyze` y `flutter test` pasan sin issues.

### Integración con el backend (autenticación exclusivamente con Google)

- CONFIGURACIÓN DE RED CENTRALIZADA: `lib/core/network/api_endpoints.dart` es la fuente única de la URL base (`ApiEndpoints.baseUrl`) según el entorno — `Environment.emulador` → `http://10.0.2.2:3000` (emulador Android), `dispositivoFisico` → IP LAN de la PC, `produccion` → dominio futuro; en web/Chrome (la app corre en la misma PC) usa `http://localhost:3000` automáticamente vía `kIsWeb`. Se cambia manualmente `ApiEndpoints.currentEnv` según dónde se pruebe. `lib/movil/core/api_config.dart` expone los getters (`baseUrl`, `authGoogle`, `authRegister`, `authPerfil`) delegando a `ApiEndpoints`. Ya no hay URLs hardcodeadas en los archivos de llamada (`auth_provider.dart` usa `ApiConfig.*`).
- `AuthProvider.signInWithGoogle()` entra con Firebase/Google, obtiene el **ID Token** de Firebase (`firebaseUser.getIdToken()`) y lo manda a `POST /api/v1/auth/google` como `{ idToken }`. El backend lo verifica server-side con `firebase-admin`, crea/actualiza `usuarios`, vincula `oauth_cuenta` (proveedor `google`, `proveedor_id` = UID verificado) y registra `ultimo_ingreso`; el JWT propio devuelto se guarda en `SessionService` (`flutter_secure_storage`). Si el backend no responde o rechaza el token, se cierra la sesión de Google y se muestra el error (sin caer a demo).
- `AuthProvider.restaurarSesion()` (se llama desde `lib/main.dart` al abrir la app) lee el JWT de `SessionService`, lo valida contra `GET /api/v1/auth/perfil` y, si el backend responde 401, limpia el storage y el usuario vuelve al login.
- Backend en desarrollo: `main.ts` escucha en `0.0.0.0` (todas las interfaces) y CORS `{ origin: true, credentials: true }`, para probar desde emulador, web y teléfono físico en la misma red.
- `AndroidManifest.xml` (main) tiene `INTERNET` + `usesCleartextTraffic` para permitir `http://` en Android 9+ durante pruebas.

### Navegación y módulo de Reservas (UI)

- `MainShell` con 5 pestañas (`HomeTab`): **Inicio**, **Reservas**, **Favoritos**, **Ubicación**, **Perfil**; usa `IndexedStack` para conservar el estado de cada pestaña y barra inferior flotante (`widgets/navigation/app_bottom_nav.dart`).
- MÓDULO DE RESERVAS (UI con datos demo): `screens/main/reservations_screen.dart` separa **Próximas** y **Historial** con tarjetas de reserva (restaurante, zona, fecha, hora, nº de personas, chip Confirmada/Completada), tarjetas de estadísticas y botón "Nueva reserva" que por ahora muestra "próximamente". Modelo `models/reservation.dart` y datos demo `mockReservations` en `data/restaurantes_mock.dart`.
- Catálogo/visualización: `home_screen.dart` lista restaurantes desde `restaurantes_mock.dart` (mock; `models/restaurant.dart`) con búsqueda y filtros por zona/cocina; `widgets/restaurant/` (restaurant_card, restaurant_card_compact, promo_card, favorite_heart). Favoritos en memoria con `FavoritesStore`/`FavoritesScope` (`providers/favorites_provider.dart`). Pantallas de ubicación y perfil de usuario (`profile_screen.dart` con nombre/correo/foto desde el provider de auth).
- PENDIENTE FRONTEND: conectar el módulo de Reservas a la API del backend (módulo 17) y reemplazar `restaurantes_mock.dart` por un repositorio HTTP real sin tocar los widgets.