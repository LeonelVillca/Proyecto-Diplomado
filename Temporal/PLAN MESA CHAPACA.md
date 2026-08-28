# PLAN DE DESARROLLO — Mesa Chapaca
Documento de trabajo para Antigravity. Contiene el plan completo dividido en
tareas pequeñas. Trabajamos **una tarea a la vez**, en el orden en que
aparecen — no se adelanta a la siguiente tarea sin autorización explícita.

---

## REGLAS DE TRABAJO (aplican a TODAS las tareas de este documento, sin excepción)

1. **Una sola tarea a la vez.** Cada tarea de este documento es un bloque de
   trabajo independiente. Al terminar una, te detienes, resumes qué hiciste,
   y **esperas mi autorización explícita** ("listo, continúa con la
   siguiente") antes de tocar la próxima. Yo necesito probar cada tarea antes
   de que sigas — no asumas que "probablemente está bien" y avances solo.
2. **Nada de código espagueti.** Cada pantalla, cada lógica de negocio, cada
   llamada a API va en su propio widget/archivo pequeño y con una sola
   responsabilidad. Si una pantalla tiene una tabla, un formulario y un
   modal, esos son **tres widgets separados en archivos separados**, no un
   solo `build()` gigante de 300 líneas.
3. **Respeta la estructura de carpetas que ya existe**, tanto en el backend
   (`src/modules/<nombre>/` con `entity`, `dto/`, `service`, `controller`,
   `module`) como en el frontend Flutter (`lib/core/`, `lib/movil/`, y el
   nuevo `lib/admin/` que se crea en este plan — cada pantalla dentro de su
   propia carpeta de feature, con `screens/`, `widgets/`, `providers/`
   propios). No crees carpetas nuevas con otro criterio ni mezcles algo de
   `movil/` dentro de `admin/` o viceversa.
4. **Seguridad, siempre presente, no al final.** Cada endpoint nuevo debe
   nacer ya con su guard de rol correspondiente (no "lo agrego después").
   Cada pantalla del panel Admin debe verificar sesión y rol antes de
   mostrar contenido, no solo ocultar visualmente un botón.
5. **Al terminar cada tarea**, actualiza `GUIA_SEGUIMIENTO.md` (marca la
   casilla) y agrega una entrada corta en `CONTEXTO_SISTEMA.md` si la tarea
   introduce algo que un agente nuevo necesitaría saber para entender el
   sistema (ej: "se agregó `lib/admin/` como nuevo punto de entrada web").
6. Si algo de este documento es ambiguo o no coincide con el código que ya
   existe, **pregunta antes de asumir** — no inventes una solución para
   rellenar el vacío.

---

## ACLARACIÓN CRÍTICA — Léela antes de empezar cualquier tarea de Fase 4

El panel administrativo (`lib/admin/`) es **exclusivamente para web** —
Admin_Restaurante y Admin_Sistema. **No es una versión "responsive" de la
app móvil, es una experiencia de diseño completamente distinta**, pensada
como una página web profesional (piensa en el nivel de diseño de una
landing SaaS moderna, no en una pantalla de celular estirada). No reutilices
patrones de navegación móvil (bottom navigation bar, gestos de swipe,
tarjetas apiladas verticales tipo feed) dentro de `lib/admin/` — usa
patrones de web real: barra de navegación superior, sidebar fijo lateral
para el dashboard interno, tablas de datos, modales, layouts de múltiples
columnas. Sí debe ser responsive (que no se rompa en una pantalla angosta),
pero su diseño base está pensado para escritorio.

La app móvil (`lib/movil/`) sigue siendo exclusivamente para el Cliente —
no le agregues nada de lo que se construya en las fases de Admin.

---

# FASE A — Seguridad y control de acceso en el backend

*(Esto extiende el trabajo de seguridad ya implementado en el módulo de
autenticación con Google — ahora toca aplicar control de roles a los
demás endpoints.)*

### [x] Tarea A1 — Infraestructura de guards
Crea (si no existe ya) en `src/core/`:
- `guards/roles.guard.ts` — verifica que el usuario autenticado tenga
  alguno de los roles requeridos por el endpoint.
- `decorators/roles.decorator.ts` — `@Roles('admin_sistema', 'admin_restaurante')`.
- `guards/ownership.guard.ts` — guard reutilizable para verificar que un
  Admin_Restaurante solo pueda modificar recursos (`restaurante`, `menu`,
  `plato`, `mesa`, `promocion`, `horario_atencion`) que le pertenecen a él
  (comparando el `id_restaurante` del recurso contra los restaurantes
  asociados al usuario autenticado vía sus roles/solicitudes aprobadas).

No apliques todavía estos guards a ningún endpoint — eso es la Tarea A2.

### [x] Tarea A2 — Aplicar guards a los módulos de Admin_Sistema
Aplica `@Roles('admin_sistema')` + `RolesGuard` a los endpoints de:
`usuarios` (suspender/activar/eliminar), `rol`, `permiso`,
`categoria_soporte`, `solicitud` (aprobar/rechazar), moderación de
`resenas` (eliminar), `reportes` generales.

### [x] Tarea A3 — Aplicar guards a los módulos de Admin_Restaurante
Aplica `@Roles('admin_restaurante')` + `RolesGuard` + `OwnershipGuard` a:
`restaurante` (editar/suspender su propio perfil), `menu`, `plato`,
`imagen`, `mesa`, `horario_atencion`, `promocion`, respuesta a `resenas`,
confirmar/rechazar `reservas` de su restaurante.

### [x] Tarea A4 — Aplicar control de propiedad a endpoints de Cliente
Verifica que un Cliente solo pueda editar/cancelar sus propias `reservas`,
editar/eliminar sus propias `resenas` (antes de que sean respondidas), y ver
únicamente sus propios `soporte` y `notificacion`.

---

# FASE B — Completar los módulos de backend que faltan

### [x] Tarea B1 — Módulo 17: Reservas + WebSocket Gateway
`reserva.entity.ts`, DTOs, service, controller. Además, el Gateway de
WebSocket que notifica en tiempo real cambios de estado de una reserva a
los clientes conectados (tanto a la futura app móvil como al futuro panel
web del restaurante).

### [x] Tarea B2 — Módulo 18: Reseñas
CRUD completo, con la regla de que un Cliente solo puede editar/eliminar su
propia reseña, y solo antes de que exista una `respuesta_resena` asociada.

### [x] Tarea B3 — Módulo 19: Respuesta a reseñas
Debe registrar `id_usuario_restaurante` (quién respondió, para auditoría) y
respetar que solo puede existir una respuesta por reseña.

### [x] Tarea B4 — Módulo Promoción
CRUD completo siguiendo el esquema ya definido (`descuento_porcentaje`,
`fecha_inicio`, `fecha_fin`, `estado`), con `OwnershipGuard` ya aplicado
desde el inicio (no dejar sin proteger y arreglar después).

### [x] Tarea B5 — Endpoint de Ranking
Un endpoint de solo lectura que consuma `vista_ranking_restaurantes`
(la vista SQL ya creada), con parámetro de ordenamiento
(`?orden=calificacion` o `?orden=visitas`) y límite configurable
(por defecto 20).

---

# FASE C — Conectar la app móvil (Cliente) a la API real

### [en progreso] Tarea C1 — Restaurantes, menú, platos y ubicación reales
Reemplaza `restaurantes_mock.dart` y cualquier dato demo asociado por
llamadas HTTP reales a `/restaurante`, `/menu`, `/plato`, `/ubicacion`,
`/imagen`. Mantén el mismo diseño visual ya aprobado — este cambio es solo
de origen de datos, no de interfaz.

### [x] Tarea C2 — Reservas en tiempo real
Conecta la pantalla de Reservas al módulo 17: creación vía REST, y
suscripción al WebSocket para reflejar cambios de estado
(confirmada/rechazada) sin que el usuario tenga que refrescar.

### [ ] Tarea C3 — Perfil del cliente: reseñas y soporte
Conecta la sección de perfil con sus propias reseñas (módulo 18) y sus
tickets de soporte (módulo `soporte`).

### [ ] Tarea C4 — Promociones y ranking en la interfaz
Muestra las promociones activas de cada restaurante en su pantalla de
detalle, y agrega una sección de "Top restaurantes" en la pantalla
principal, consumiendo el endpoint de ranking de la Tarea B5.

---

# FASE D — Panel Web: acceso público y autenticación
*(A partir de aquí, todo vive en `lib/admin/`. Diseño de nivel web
profesional — revisa la aclaración crítica de arriba antes de empezar.)*

### [x] Tarea D1 — Landing pública
Página de inicio pública (sin necesidad de sesión), con:
- Barra de navegación superior con el logo y enlaces/beneficios de unirse a
  la plataforma (ej: "Más reservas", "Gestión simple", "Visibilidad en
  Tarija" — redacta contenido apropiado).
- Dos botones claramente visibles en la barra: **"Comienza"** y
  **"Acceso"**.
- Cuerpo de la landing con secciones explicando los beneficios de sumar su
  restaurante a la plataforma (usa buen diseño visual, no placeholder
  genérico — imágenes/ilustraciones, no solo texto).

### [x] Tarea D2 — Flujo "Comienza" (formulario de solicitud)
Al presionar "Comienza": pantalla de bienvenida breve, seguida del
formulario de solicitud con estos campos exactos: **nombre, apellido,
correo electrónico, nombre del restaurante, número de teléfono, y un
mensaje/descripción de la solicitud**. Al enviar, muestra una pantalla de
confirmación ("Solicitud enviada con éxito"), y después de unos segundos (o
con un botón "Volver al inicio") regresa a la landing pública. Conecta este
formulario al endpoint real de `solicitud` (`POST /solicitud`).

### [x] Tarea D3 — Flujo "Acceso" (login)
Al presionar "Acceso": pantalla de login con una imagen de fondo de un
restaurante (usa buen criterio visual, imagen de calidad, no un placeholder
gris), con **únicamente dos campos: correo electrónico y contraseña** — sin
botón de Google aquí (recuerda: el login administrativo web usa
correo/contraseña, no Google, eso es exclusivo de la app móvil del
Cliente). Conecta contra el endpoint de autenticación local ya existente
en el backend.

### [x] Tarea D4 — Enrutamiento post-login por rol
Después de un login exitoso, redirige según el rol del usuario autenticado:
`admin_sistema` → dashboard de sistema (Fase E), `admin_restaurante` →
dashboard de restaurante (Fase F). Si el usuario no tiene ninguno de esos
roles, muestra un mensaje claro de que no tiene acceso al panel
administrativo (no lo dejes en una pantalla en blanco o un error crudo).

---

# FASE E — Panel Web: Dashboard de Admin_Sistema

### [x] Tarea E1 — Aprobar/rechazar solicitudes
Listado de `solicitud` con filtro por estado, vista de detalle con los
datos enviados en el formulario (Tarea D2) y sus `documento_adjunto`, y
acciones de aprobar/rechazar (con campo de motivo si se rechaza).

### [x] Tarea E2 — Gestión de usuarios, roles y permisos
Listado/búsqueda de `usuarios` (activar/suspender), gestión de `rol` y
`permiso` (según lo que ya definimos: crear roles y asignarles permisos
desde `rol_permiso`).

### [x] Tarea E3 — Moderación de reseñas y reportes generales
Listado de `resenas` con opción de eliminar contenido inapropiado, y
sección de generación de `reportes` con filtros de fecha y tipo.

---

# FASE F — Panel Web: Dashboard de Admin_Restaurante

*(Para el diseño de estas pantallas, usa como referencia funcional — no
visual exacta — la documentación de casos de uso que ya te compartí:
sidebar con Reservas / Reportes / Soporte / Configuraciones / Perfil de
Restaurante / Gestión de Menús, y tabla de contenido con buscador, filtros y
acciones por fila.)*

### [x] Tarea F1 — Perfil del restaurante
Formulario de perfil (nombre, tipo de comida, descripción, teléfono,
correo, foto de portada, ubicación con mapa/coordenadas), editable por el
dueño ya aprobado.

### [x] Tarea F2 — Gestión de mesas
CRUD de `mesa` (número, capacidad, estado) y de `horario_atencion`.

### [x] Tarea F3 — Gestión de menús y platillos
Sigue este patrón exacto de la documentación original: pantalla "Gestión de
Menús" con listado (nombre, tipo, cantidad de platillos, estado
activo/inactivo, acciones editar/eliminar/habilitar). Pantalla "Crear
Menú": nombre del menú, tipo (Diario / Fin de semana / Especial vía
dropdown), y una sección para agregar platillos uno por uno — cada platillo
con foto, nombre, descripción y precio (en Bs), con un botón "+" para
agregar otro platillo al mismo menú antes de guardar.

### [x] Tarea F4 — Gestión de promociones
CRUD de `promocion` del propio restaurante.

### [x] Tarea F5 — Reservas en tiempo real
Listado de reservas entrantes (conectado al WebSocket del módulo 17), con
acciones de confirmar/rechazar, actualizándose sin recargar la página.

### [x] Tarea F6 — Responder reseñas
Listado de reseñas recibidas con opción de responder (una sola vez por
reseña).

### [x] Tarea F7 — Soporte y reportes del restaurante
Crear/ver tickets de soporte propios, y reportes acotados a su propio
restaurante (reservas, calificación, visitas).

---

## AL EMPEZAR

Antes de tocar código, confirma que entendiste el plan completo, dime
cuántas sub-tareas más pequeñas propones dentro de la **Tarea A1** (la
primera de la lista), y espera mi autorización para arrancar.


Aquí tienes el prompt completo respetando cada una de tus instrucciones originales, incorporando al detalle la arquitectura y reglas de almacenamiento (publico/ vs privado/, IDs de entidad, UUIDs y seguridad) que definimos:

ACTUALIZACIÓN — Flujo real de Solicitud → Aprobación → Acceso
Este bloque CORRIGE y AMPLÍA las tareas D2, D3, D4 y E1 que ya están
marcadas como completadas en el plan. No las tratamos como tareas nuevas
desde cero — son enmiendas sobre código que ya existe y ya funciona
parcialmente. Antes de tocar nada, revisa cómo está construido D2, D3, D4
y E1 actualmente y confírmame qué encontraste, antes de modificar.

REGLA DE ARQUITECTURA DE ALMACENAMIENTO (Aplica a todo el sistema)
La gestión de archivos en disco se organiza estrictamente por ID de entidad, nunca por fechas (YYYY/MM/DD), y con separación absoluta entre recursos públicos y sensibles desde la raíz:

Plaintext
storage/
├── publico/                          ← Servido como estático (useStaticAssets)
│   └── restaurantes/
│       └── {id_restaurante}/
│           ├── portada/
│           │   └── {uuid}.webp
│           ├── galeria/
│           │   └── {uuid}.webp
│           └── platos/
│               └── {id_plato}/
│                   └── {uuid}.webp
│
└── privado/                          ← NUNCA estático, acceso solo por Controller + Guard
    └── solicitudes/
        └── {id_solicitud}/
            ├── nit-{uuid}.pdf
            └── ci-{uuid}.pdf
Nombres de archivo: Nunca usar el nombre original subido por el cliente. Renombrar siempre con UUID para evitar colisiones y path traversal.

Base de Datos: Guardar únicamente la ruta relativa normalizada (ej: /privado/solicitudes/15/nit-uuid.pdf).

Limpieza: En caso de rechazo o eliminación, borrar la carpeta completa del ID correspondiente (privado/solicitudes/{id_solicitud}/).

PASO 0 — Cambio de base de datos (bloqueante, hazlo primero)
Agrega esta tabla nueva a la base de datos (ejecútala en PostgreSQL,
avísame para correrla yo mismo si prefieres que la ejecute manualmente en
pgAdmin en vez de que la corras tú):

SQL
CREATE TABLE invitacion_token (
  id_token          SERIAL PRIMARY KEY,
  id_usuario        INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  token             VARCHAR(255) NOT NULL UNIQUE,
  tipo              VARCHAR(30) NOT NULL DEFAULT 'invitacion'
                    CHECK (tipo IN ('invitacion', 'reset_password')),
  usado             BOOLEAN NOT NULL DEFAULT false,
  fecha_creacion    TIMESTAMP NOT NULL DEFAULT now(),
  fecha_expiracion  TIMESTAMP NOT NULL
);

CREATE INDEX idx_invitacion_token_token ON invitacion_token(token);
Nota: esta misma tabla la vamos a reutilizar más adelante para
"recuperar contraseña" (tipo reset_password) — no es exclusiva de la
invitación inicial, así que constrúyela pensando en ambos usos desde ya.

Crea el módulo invitacion-token en el backend siguiendo la misma
estructura que los demás (entity, service — no necesita controller propio,
lo usan otros services internamente).

Tarea D2-REV — Ampliar el formulario de "Comienza" con sub-paso de documentos
Revisa el POST /solicitud actual. Debe pasar de guardar solo los campos
livianos (nombre, apellido, correo, nombre_restaurante, teléfono, mensaje)
a un flujo de 2 sub-pasos dentro de la misma pantalla/flujo, sin volver
a la landing entre uno y otro:

Sub-paso 1 (ya existe, no lo toques si ya funciona bien): los campos
livianos actuales.

Sub-paso 2 (nuevo, agrégalo a continuación del anterior):

Campo de texto nit_negocio.

Subir documento tipo NIT (usa el mismo servicio de almacenamiento de
archivos que ya implementaste para las fotos de menú en la Tarea F3 —
verifica primero si ese servicio acepta PDF además de imágenes, un
documento de NIT/CI puede venir en cualquiera de los dos formatos; si
solo acepta imágenes, amplíalo para aceptar también PDF).

Subir documento tipo CI (mismo mecanismo).

Estructura y persistencia física de archivos en D2-REV:

Al recibir los archivos de la solicitud, guárdalos en la ruta privada:
storage/privado/solicitudes/{id_solicitud}/nit-{uuid}.[pdf|jpg|png]
storage/privado/solicitudes/{id_solicitud}/ci-{uuid}.[pdf|jpg|png]

No los guardes en carpetas públicas.

Al enviar el sub-paso 2 completo, el backend hace, en una sola transacción:

Crea usuarios (nombre, apellido, correo) — sin fila en
cuentas_auth todavía.

Crea solicitud (id_usuario, estado='pendiente', nombre_restaurante,
nit_negocio, celular_contacto, descripcion).

Crea dos filas en documento_adjunto (tipo='NIT' y tipo='CI')
asociadas a esa solicitud con la ruta relativa del archivo.

Termina con la pantalla de confirmación que ya existe ("Solicitud enviada
con éxito") y vuelve a la landing.

Si el correo ya existe en usuarios (alguien que ya envió una
solicitud antes, o que ya tiene cuenta por algún otro medio), no crees un
usuario duplicado — usa el ya existente y valida el estado de su solicitud
anterior antes de permitir una nueva.

Tarea D-NUEVA-1 — Servicio de invitación tras aprobación (backend)
Dentro del endpoint de aprobar solicitud (ya existente en E1, revisa el
service de solicitud), agrega esta lógica cuando el estado cambia a
aprobada:

Asigna el rol admin_restaurante en usuario_rol para el
id_usuario de esa solicitud.

Genera un token aleatorio seguro (usa crypto.randomBytes o similar,
no algo predecible), guárdalo en invitacion_token
(tipo='invitacion', fecha_expiracion = 48 horas desde ahora).

Envía un correo real (confirma primero que el servicio de correo esté
configurado de verdad, con envío real — si no lo está, avísame antes de
seguir, es bloqueante) con un enlace tipo:
https://[dominio-admin]/crear-contrasena?token=xxxxx

Si la solicitud se rechaza, no generes ningún token — solo notifica el
rechazo con el motivo_rechazo y elimina la carpeta de documentos
storage/privado/solicitudes/{id_solicitud}/ del servidor para no acumular basura.

Tarea D-NUEVA-2 — Pantalla "Crear tu contraseña" (frontend, lib/admin/)
Pantalla pública (sin sesión) que recibe el token por parámetro de URL,
con dos campos: contraseña y confirmar contraseña. Al enviar:

Backend valida que el token exista, no esté usado y no haya expirado.

Si es válido: crea la fila en cuentas_auth con el password_hash,
marca el token como usado=true, y redirige a la pantalla de login
(Tarea D3) con un mensaje de éxito.

Si es inválido/expirado: muestra un mensaje claro y un botón para
solicitar que le reenvíen la invitación (no lo dejes sin salida).

Tarea E1-REV — Visor de documentos en el panel de aprobación
Amplía la pantalla de revisión de solicitudes (Tarea E1, ya construida)
para mostrar los documento_adjunto asociados:

Debe soportar visualización inline tanto de imágenes como de PDF (no
asumas un solo formato).

Importante — privacidad: estos documentos contienen datos personales
sensibles (CI, NIT). No uses URLs públicas permanentes ni sirvas la carpeta
privado/ con useStaticAssets. Sirve los archivos exclusivamente a
través de un endpoint del backend protegido por RolesGuard
(admin_sistema) usando res.sendFile() (o streams con validación de sesión) —
nunca un link directo y público al archivo.

Muestra también el nit_negocio como texto junto a los documentos, no
solo el archivo.

RECORDATORIOS (aplican también a este bloque, ya los conoces)
Una tarea a la vez, esperas mi autorización antes de la siguiente.

Actualiza GUIA_SEGUIMIENTO.md y CONTEXTO_SISTEMA.md al terminar cada
una — en CONTEXTO_SISTEMA.md deja explícito que se agregó la tabla
invitacion_token, la separación física publico/ vs privado/ para
archivos, y que el login del panel Admin ya no depende de que el
Admin_Sistema cree contraseñas manualmente, ahora es autoservicio vía
invitación.

Antes de tocar D2, D3, D4 o E1, confírmame que revisaste el código actual
y que entendiste qué falta — no asumas que puedes reescribir sin mirar
primero lo que ya existe y funciona.





& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000






Análisis de Estado del Sistema "Mesa Chapaca"
He realizado una auditoría exhaustiva del código actual comparándolo con el documento maestro PLAN MESA CHAPACA.md. Este es el estado real y técnico del proyecto:

✅ 1. Backend y Base de Datos (Completado al 100%)
Todas las tareas de las Fases A y B están completamente finalizadas y desplegadas en NestJS con TypeORM:

Infraestructura de Seguridad: RolesGuard y OwnershipGuard están protegiendo correctamente todos los endpoints.
Módulos operativos: Usuarios, Auth, Restaurantes, Solicitudes, Menús, Platos, Ubicación, Horarios, Mesas, Imágenes, Promociones, Reseñas, Soporte y Reservas (incluyendo el WebSocket ReservaGateway).
Vista SQL y Reportes: Endpoint de Ranking y Reportes analíticos operativos.
Archivos: Flujo correcto de guardado separado entre publico/ (imágenes de restaurante/platos) y privado/ (documentos sensibles CI/NIT).
Invitaciones Automáticas: Módulo invitacion-token para registro de administradores de restaurante.
✅ 2. Panel Administrativo Web (Completado al 100%)
Las Fases D, E y F están completamente funcionales bajo la carpeta lib/screens/admin/:

Landing pública y flujo de solicitud con subida de documentos (NIT/CI).
Panel Admin_Sistema para aprobar solicitudes, revisar PDFs privados y gestionar usuarios.
Panel Admin_Restaurante para editar perfil, mapas, gestionar menús/platillos con fotos, ver reservas en tiempo real y responder reseñas.
🚧 3. Lo que falta: Frontend Móvil (Fase C - En progreso)
El backend y el panel web ya están listos, el único frente abierto es conectar las funciones restantes a la App Móvil.

Actualmente, el Home, el Mapa y el Detalle del Restaurante ya muestran los datos, menús, fotos y ubicación real de la base de datos (lo que acabamos de terminar en la Tarea C1). Sin embargo, quedan pendientes las siguientes conexiones:

🔴 Pendiente 1: Reservas en Tiempo Real (Tarea C2)
Estado actual: La vista reservas_screen.dart y el botón "Reservar mesa" todavía no interactúan con el backend.
Lo que hay que hacer:
Crear el formulario para que el cliente elija la fecha, hora, cantidad de personas y lance un POST /reserva.
Conectar el cliente móvil al WebSocket (ReservaGateway) para que si el administrador aprueba/rechaza la reserva en su panel web, el celular del cliente se actualice y envíe una alerta instantánea sin recargar la pantalla.
🔴 Pendiente 2: Perfil del Cliente - Reseñas y Soporte (Tarea C3)
Estado actual: La pantalla de Perfil es un cascarón visual estático.
Lo que hay que hacer:
Habilitar que el cliente pueda dejar una reseña (POST /resenas) y ver/editar las suyas en su perfil.
Habilitar la creación de tickets de soporte (POST /soporte) desde la app para el Admin_Sistema.
🔴 Pendiente 3: Promociones y Ranking (Tarea C4)
Estado actual: home_screen.dart ordena los restaurantes con una función temporal en el frontend (_getTrending). El carrusel de promociones se eliminó temporalmente por ser falso.
Lo que hay que hacer:
Hacer que el Home consuma el endpoint real GET /restaurante/ranking para mostrar las verdaderas tendencias.
Mostrar las promociones vigentes de cada restaurante (Módulo Promoción).
🔴 Detalles menores de UI (Móvil)
Favoritos: El corazón de "Favoritos" (favorite_heart.dart) actualmente no guarda el estado en la base de datos de los usuarios.
Buscador y Filtros: Las barras de búsqueda del Home y Mapa muestran un mensaje de "Próximamente". Se deben conectar al filtro del backend.
Conclusión y Siguiente Paso
El proyecto está en su recta final (90% completado). Toda la lógica compleja de negocio ya existe en el servidor; solo nos falta armar los "cables" de la app de los clientes.

👉 ¿Te parece si atacamos primero el "Pendiente 1" (Tarea C2: Reservas en Tiempo Real)? Esto permitirá conectar la experiencia de que un cliente pida una mesa en la App, y al administrador le suene la notificación en su panel Web.


