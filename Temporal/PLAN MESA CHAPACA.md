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

### Tarea A1 — Infraestructura de guards
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

### Tarea A2 — Aplicar guards a los módulos de Admin_Sistema
Aplica `@Roles('admin_sistema')` + `RolesGuard` a los endpoints de:
`usuarios` (suspender/activar/eliminar), `rol`, `permiso`,
`categoria_soporte`, `solicitud` (aprobar/rechazar), moderación de
`resenas` (eliminar), `reportes` generales.

### Tarea A3 — Aplicar guards a los módulos de Admin_Restaurante
Aplica `@Roles('admin_restaurante')` + `RolesGuard` + `OwnershipGuard` a:
`restaurante` (editar/suspender su propio perfil), `menu`, `plato`,
`imagen`, `mesa`, `horario_atencion`, `promocion`, respuesta a `resenas`,
confirmar/rechazar `reservas` de su restaurante.

### Tarea A4 — Aplicar control de propiedad a endpoints de Cliente
Verifica que un Cliente solo pueda editar/cancelar sus propias `reservas`,
editar/eliminar sus propias `resenas` (antes de que sean respondidas), y ver
únicamente sus propios `soporte` y `notificacion`.

---

# FASE B — Completar los módulos de backend que faltan

### Tarea B1 — Módulo 17: Reservas + WebSocket Gateway
`reserva.entity.ts`, DTOs, service, controller. Además, el Gateway de
WebSocket que notifica en tiempo real cambios de estado de una reserva a
los clientes conectados (tanto a la futura app móvil como al futuro panel
web del restaurante).

### Tarea B2 — Módulo 18: Reseñas
CRUD completo, con la regla de que un Cliente solo puede editar/eliminar su
propia reseña, y solo antes de que exista una `respuesta_resena` asociada.

### Tarea B3 — Módulo 19: Respuesta a reseñas
Debe registrar `id_usuario_restaurante` (quién respondió, para auditoría) y
respetar que solo puede existir una respuesta por reseña.

### Tarea B4 — Módulo Promoción
CRUD completo siguiendo el esquema ya definido (`descuento_porcentaje`,
`fecha_inicio`, `fecha_fin`, `estado`), con `OwnershipGuard` ya aplicado
desde el inicio (no dejar sin proteger y arreglar después).

### Tarea B5 — Endpoint de Ranking
Un endpoint de solo lectura que consuma `vista_ranking_restaurantes`
(la vista SQL ya creada), con parámetro de ordenamiento
(`?orden=calificacion` o `?orden=visitas`) y límite configurable
(por defecto 20).

---

# FASE C — Conectar la app móvil (Cliente) a la API real

### Tarea C1 — Restaurantes, menú, platos y ubicación reales
Reemplaza `restaurantes_mock.dart` y cualquier dato demo asociado por
llamadas HTTP reales a `/restaurante`, `/menu`, `/plato`, `/ubicacion`,
`/imagen`. Mantén el mismo diseño visual ya aprobado — este cambio es solo
de origen de datos, no de interfaz.

### Tarea C2 — Reservas en tiempo real
Conecta la pantalla de Reservas al módulo 17: creación vía REST, y
suscripción al WebSocket para reflejar cambios de estado
(confirmada/rechazada) sin que el usuario tenga que refrescar.

### Tarea C3 — Perfil del cliente: reseñas y soporte
Conecta la sección de perfil con sus propias reseñas (módulo 18) y sus
tickets de soporte (módulo `soporte`).

### Tarea C4 — Promociones y ranking en la interfaz
Muestra las promociones activas de cada restaurante en su pantalla de
detalle, y agrega una sección de "Top restaurantes" en la pantalla
principal, consumiendo el endpoint de ranking de la Tarea B5.

---

# FASE D — Panel Web: acceso público y autenticación
*(A partir de aquí, todo vive en `lib/admin/`. Diseño de nivel web
profesional — revisa la aclaración crítica de arriba antes de empezar.)*

### Tarea D1 — Landing pública
Página de inicio pública (sin necesidad de sesión), con:
- Barra de navegación superior con el logo y enlaces/beneficios de unirse a
  la plataforma (ej: "Más reservas", "Gestión simple", "Visibilidad en
  Tarija" — redacta contenido apropiado).
- Dos botones claramente visibles en la barra: **"Comienza"** y
  **"Acceso"**.
- Cuerpo de la landing con secciones explicando los beneficios de sumar su
  restaurante a la plataforma (usa buen diseño visual, no placeholder
  genérico — imágenes/ilustraciones, no solo texto).

### Tarea D2 — Flujo "Comienza" (formulario de solicitud)
Al presionar "Comienza": pantalla de bienvenida breve, seguida del
formulario de solicitud con estos campos exactos: **nombre, apellido,
correo electrónico, nombre del restaurante, número de teléfono, y un
mensaje/descripción de la solicitud**. Al enviar, muestra una pantalla de
confirmación ("Solicitud enviada con éxito"), y después de unos segundos (o
con un botón "Volver al inicio") regresa a la landing pública. Conecta este
formulario al endpoint real de `solicitud` (`POST /solicitud`).

### Tarea D3 — Flujo "Acceso" (login)
Al presionar "Acceso": pantalla de login con una imagen de fondo de un
restaurante (usa buen criterio visual, imagen de calidad, no un placeholder
gris), con **únicamente dos campos: correo electrónico y contraseña** — sin
botón de Google aquí (recuerda: el login administrativo web usa
correo/contraseña, no Google, eso es exclusivo de la app móvil del
Cliente). Conecta contra el endpoint de autenticación local ya existente
en el backend.

### Tarea D4 — Enrutamiento post-login por rol
Después de un login exitoso, redirige según el rol del usuario autenticado:
`admin_sistema` → dashboard de sistema (Fase E), `admin_restaurante` →
dashboard de restaurante (Fase F). Si el usuario no tiene ninguno de esos
roles, muestra un mensaje claro de que no tiene acceso al panel
administrativo (no lo dejes en una pantalla en blanco o un error crudo).

---

# FASE E — Panel Web: Dashboard de Admin_Sistema

### Tarea E1 — Aprobar/rechazar solicitudes
Listado de `solicitud` con filtro por estado, vista de detalle con los
datos enviados en el formulario (Tarea D2) y sus `documento_adjunto`, y
acciones de aprobar/rechazar (con campo de motivo si se rechaza).

### Tarea E2 — Gestión de usuarios, roles y permisos
Listado/búsqueda de `usuarios` (activar/suspender), gestión de `rol` y
`permiso` (según lo que ya definimos: crear roles y asignarles permisos
desde `rol_permiso`).

### Tarea E3 — Moderación de reseñas y reportes generales
Listado de `resenas` con opción de eliminar contenido inapropiado, y
sección de generación de `reportes` con filtros de fecha y tipo.

---

# FASE F — Panel Web: Dashboard de Admin_Restaurante

*(Para el diseño de estas pantallas, usa como referencia funcional — no
visual exacta — la documentación de casos de uso que ya te compartí:
sidebar con Reservas / Reportes / Soporte / Configuraciones / Perfil de
Restaurante / Gestión de Menús, y tabla de contenido con buscador, filtros y
acciones por fila.)*

### Tarea F1 — Perfil del restaurante
Formulario de perfil (nombre, tipo de comida, descripción, teléfono,
correo, foto de portada, ubicación con mapa/coordenadas), editable por el
dueño ya aprobado.

### Tarea F2 — Gestión de mesas
CRUD de `mesa` (número, capacidad, estado) y de `horario_atencion`.

### Tarea F3 — Gestión de menús y platillos
Sigue este patrón exacto de la documentación original: pantalla "Gestión de
Menús" con listado (nombre, tipo, cantidad de platillos, estado
activo/inactivo, acciones editar/eliminar/habilitar). Pantalla "Crear
Menú": nombre del menú, tipo (Diario / Fin de semana / Especial vía
dropdown), y una sección para agregar platillos uno por uno — cada platillo
con foto, nombre, descripción y precio (en Bs), con un botón "+" para
agregar otro platillo al mismo menú antes de guardar.

### Tarea F4 — Gestión de promociones
CRUD de `promocion` del propio restaurante.

### Tarea F5 — Reservas en tiempo real
Listado de reservas entrantes (conectado al WebSocket del módulo 17), con
acciones de confirmar/rechazar, actualizándose sin recargar la página.

### Tarea F6 — Responder reseñas
Listado de reseñas recibidas con opción de responder (una sola vez por
reseña).

### Tarea F7 — Soporte y reportes del restaurante
Crear/ver tickets de soporte propios, y reportes acotados a su propio
restaurante (reservas, calificación, visitas).

---

## AL EMPEZAR

Antes de tocar código, confirma que entendiste el plan completo, dime
cuántas sub-tareas más pequeñas propones dentro de la **Tarea A1** (la
primera de la lista), y espera mi autorización para arrancar.