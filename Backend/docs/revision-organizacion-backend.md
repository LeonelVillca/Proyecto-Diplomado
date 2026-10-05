# Revisión de organización del backend

Fecha: 5 de octubre de 2026.

## Avance de la etapa 1

El diagnóstico de este documento registra el estado inicial. La primera etapa ya se implementó: `usuario-restaurante/usuario-restaurante-acceso.service.ts` define la regla compartida de rol y asignación activa que ahora consultan `OwnershipGuard`, `ReservasController` y `ReservasGateway`. El cliente de la reserva sigue recibiendo su propio evento; el administrador de sistema conserva el acceso. Las rutas y respuestas HTTP no se modificaron.

Se corrigió el tipado de las pruebas de autenticación, disponibilidad de reservas y solicitud que impedía comprobar todo el proyecto. Verificación posterior: comprobación completa de tipos, compilación de producción, 22 suites/103 pruebas unitarias y 4 suites/19 pruebas E3 con PostgreSQL aislado, todas aprobadas. Las etapas 4 y 5 se documentan más adelante.

## Avance de la etapa 2

`restaurante.service.ts` conserva el contrato del controlador y delega la coordinación del perfil a `services/perfil-restaurante.service.ts`, la regla de publicación a `services/publicacion-restaurante.service.ts` y las consultas de catálogo y gestión a `queries/restaurante-consultas.service.ts`. Las respuestas de catálogo y `mis-restaurantes` mantienen los campos usados por Flutter. La actualización de restaurante, ubicación, horarios, mesas y activación del perfil se evalúa dentro de una misma transacción.

La provisión excepcional desde una solicitud aprobada ahora usa una transacción y un bloqueo por usuario; reutiliza el restaurante existente y no reactiva una asignación revocada por una lectura. Se añadieron pruebas del contrato del catálogo, la política de publicación, la transacción de actualización y una prueba HTTP con PostgreSQL aislado. Verificación: tipos completos y compilación aprobados; 23 suites/107 pruebas unitarias y 4 suites/20 pruebas E3 aprobadas. La base local de trabajo no se modificó en esta etapa.

## Avance de la etapa 3

`plato/dto/datos-plato.dto.ts` define el esquema que usan tanto el plato individual como el plato anidado en el menú; incluye validación numérica del precio. `horario-atencion/dto/datos-horario-atencion.dto.ts` define día y horas para las rutas individuales y para el perfil de restaurante. Los DTO de entrada conservan sus identificadores propios (`idMenu` o `idRestaurante`) solo donde se necesitan.

`MenuService` delega la creación y sustitución de platos a `PlatoService` pasando el mismo `EntityManager` de la transacción. La edición desde Flutter sigue reemplazando la lista completa: los platos recreados reciben identificadores nuevos, como antes. `PerfilRestauranteService` delega la sustitución semanal a `HorarioAtencionService` con el mismo `EntityManager`; las demás escrituras del perfil y su publicación permanecen en una transacción. No se cambiaron rutas ni esquemas de PostgreSQL.

Verificación: tipos completos, compilación y lint de producción correctos; 23 suites/107 pruebas unitarias y 4 suites/23 pruebas E3 con PostgreSQL aislado. La suite E3 cubre creación individual y anidada, sustitución de platos, actualización de horarios y rechazo de entradas inválidas sin alterar datos existentes. La base local de trabajo no se modificó en esta etapa.

## Avance de la etapa 4

Las reglas temporales de la mesa se concentran en `mesa/mesa-estado.ts`: vencimiento de estados manuales, evaluación de estado en un horario, consulta de bloqueos y escritura de bloqueos. `MesaService` y `ReservasService` consumen las mismas reglas y constantes de duración y margen previo. Las consultas de disponibilidad y el solapamiento de reservas permanecen en `reservas`; las rutas y respuestas no cambiaron.

La escritura de bloqueos y reservas conserva la transacción y el bloqueo de la fila de mesa. Las pruebas con PostgreSQL aislado comprueban dos reservas simultáneas, una reserva concurrente con un bloqueo manual y los límites exactos de los intervalos de reserva y bloqueo. No se añadieron migraciones ni se alteró la base local de trabajo.

## Avance de la etapa 5

`AuthModule` inicializa Firebase Admin una sola vez y comparte la aplicación con autenticación y notificaciones. `StorageModule` comparte el cliente R2 para documentos y para imágenes públicas. Las cargas nuevas de portada, logo, galería y plato guardan archivos en `storage/publico` durante desarrollo y en R2 cuando `NODE_ENV=production`; la API sirve las imágenes desde `/api/v1/publico/restaurantes/...`. Las URLs antiguas de Cloudinary que ya estén registradas permanecen utilizables, y las rutas antiguas `/publico/...` de archivos locales siguen disponibles.

Los campos de respuesta para Flutter (`fotoPortada`, `logo`, `imagenes[].url` y `url` en la carga de plato) mantienen sus nombres y reciben URLs que el cliente ya sabe resolver. La consulta del catálogo carga ubicación, horarios, mesas, imágenes y reseñas por grupos, evitando cinco lecturas por cada restaurante. Las pruebas cubren la selección de almacenamiento local/R2, el contrato del catálogo y la descarga HTTP de una imagen local. Verificación: tipos, compilación y lint correctos; 24 suites/110 pruebas unitarias y 4 suites/27 pruebas E3 con PostgreSQL aislado. No se modificaron las tablas ni la base de trabajo. La comunicación con un bucket R2 real requiere validación en el entorno de producción.

## Alcance y resultado

Revisión de la estructura, dependencias, rutas, servicios, DTO, entidades y consultas que participan en la app móvil y en la administración de restaurante. Se contrastaron las rutas con sus consumidores en Flutter. No se auditó la funcionalidad propia del administrador de sistema; solo se observaron sus límites cuando comparte archivos con estos flujos.

**Resultado: las carpetas principales están bien identificadas, pero la lógica todavía no está completamente separada por responsabilidad.** Los problemas más claros están en restaurante, menú/plato, mesa/reservas y la autorización de restaurante. No conviene mover todo dentro de `restaurante`: ubicación, horarios, mesas, menú y reseñas tienen responsabilidades propias.

Esta revisión no modifica código funcional ni aplica migraciones. Las observaciones funcionales indicadas se basan en el código; no se reprodujeron contra una base de datos real.

## Inventario del alcance

Los 13 módulos de negocio de esta tabla tienen archivo de módulo, controlador, servicio, entidad y DTO dentro de su propia carpeta.

| Módulo | Qué contiene y cómo participa | Evaluación estructural |
| --- | --- | --- |
| `restaurante` | Perfil, catálogo, ranking, tipos de comida y publicación | Carpeta correcta; servicio concentra demasiadas responsabilidades |
| `ubicacion` | Dirección y coordenadas | Estructura completa; escritura también implementada desde restaurante |
| `horario-atencion` | Franjas semanales y excepciones por fecha | Excepciones bien agrupadas; esquema y escritura semanal duplicados |
| `mesa` | Mesas, capacidad, estados y bloqueos manuales por horario | Estructura completa; comparte reglas y SQL con reservas |
| `menu` | Menús y disponibilidad | Estructura completa; también administra directamente platos |
| `plato` | Platos, precio, disponibilidad y foto | Estructura completa; subida de foto implementada en el controlador |
| `imagen` | Registros de galería y eliminación | Estructura completa; subida y parte de la persistencia están en restaurante |
| `reservas` | Creación, disponibilidad, ocupación, estados, cancelación y eventos | Archivos bien ubicados; servicio amplio y permisos repartidos |
| `resenas` | Reseñas, elegibilidad, consultas y plazo entre publicaciones | Responsabilidad reconocible; consultas de estadísticas duplicadas en restaurante |
| `respuesta-resena` | Respuestas del restaurante a reseñas | Separación razonable; conservar como responsabilidad propia |
| `notificaciones` | Avisos, dispositivos y envío push | Entidades y DTO bien agrupados; inicialización Firebase repetida |
| `soporte` | Crear y consultar tickets propios | Organización reconocible; no hace falta moverlo a restaurante |
| `categoria-soporte` | Catálogo usado por ambos tipos de usuario | Organización reconocible; carga de datos iniciales dentro del servicio |

Dependencias compartidas inspeccionadas: `auth`, `usuarios`, `cuentas-auth`, `oauth-cuenta`, `invitacion-token`, `mail`, `usuario-restaurante`, y guardas/configuración/almacenamiento en `core`. Sus operaciones administrativas exclusivas quedan fuera del diagnóstico.

`auth` no necesita entidad propia porque coordina identidad y credenciales de otros módulos. `mail` no necesita CRUD, entidad ni DTO de entrada HTTP. `invitacion-token` puede ser un servicio interno sin controlador. La ausencia de esos archivos no significa que estén incompletos.

`usuario-restaurante` contiene únicamente su entidad: no rompe por sí mismo el funcionamiento, pero la consulta de asignaciones está distribuida en varias partes. Es una oportunidad concreta para centralizarla, no una razón para generar un CRUD innecesario.

## Hallazgos que conviene resolver primero

### 1. Autorización del restaurante con dos fuentes distintas

Evidencia:

- `src/core/guards/ownership.guard.ts`: usa asignaciones activas de `UsuarioRestaurante`.
- `src/modules/reservas/reservas.controller.ts:106`: también consulta `UsuarioRestaurante` para leer una reserva.
- `src/modules/reservas/reservas.gateway.ts:56`: carga el restaurante con su solicitud.
- `src/modules/reservas/reservas.gateway.ts:65`: decide quién recibe eventos por `solicitud.usuario`, en lugar de la asignación activa.

Consecuencia derivada del código: un administrador asignado que no sea el usuario de la solicitud puede gestionar reservas por HTTP y no recibir los eventos correspondientes. Un antiguo dueño de la solicitud podría seguir recibiéndolos si conserva el rol aunque ya no tenga asignación activa. No se reprodujeron estos escenarios en una sesión real.

Propuesta: crear un servicio de acceso en `usuario-restaurante` y usar la misma regla en guardas, consulta de reservas y gateway. Conservar la revalidación de sesión de los sockets.

### 2. Restaurante escribe datos que también administran otros módulos

Evidencia: `src/modules/restaurante/restaurante.service.ts:421` implementa una actualización conjunta que guarda `Ubicacion`, borra/recrea `HorarioAtencion` y genera `Mesa`. La galería se persiste allí en `:595`, aunque existe `ImagenService`.

Coordinar el guardado de un perfil completo es razonable. La mezcla aparece porque las operaciones de los módulos hijos están implementadas de nuevo dentro del servicio de restaurante, sin reutilizar una única lógica de dominio.

Propuesta: separar un servicio de perfil dentro de `restaurante` para coordinar la operación. Ubicación, horarios, mesas e imágenes deben conservar sus operaciones y validaciones en sus módulos. Las operaciones conjuntas deben recibir el mismo `EntityManager` para preservar la transacción; no sustituirlas por llamadas independientes que puedan dejar un perfil guardado a medias.

Detalle funcional observado en la generación inicial de mesas (`:516`): para 10 personas y 3 mesas, `Math.floor(10 / 3)` crea capacidad total 9. Además, esos totales solo generan mesas cuando no existe ninguna. Antes de reorganizar, definir si los totales representan únicamente la configuración inicial o deben actualizar mesas existentes; si la capacidad debe ser exacta, repartir el resto.

### 3. Menú y plato tienen dos implementaciones de creación

Evidencia: `src/modules/menu/menu.service.ts:17` crea platos con el administrador de la transacción; `:77` actualiza el menú y `:87` borra todos sus platos para recrearlos. `src/modules/plato/plato.service.ts` tiene la creación y actualización individual.

El formulario de menús del administrador usa esta operación conjunta, por lo que hay que conservar su contrato. La creación anidada puede ser válida; lo que conviene unificar son las reglas y el esquema del plato. El reemplazo actual genera nuevos identificadores, incluso para platos que no cambiaron.

Propuesta: ubicar el esquema de datos del plato en `plato/dto` y exponer operaciones internas de platos que acepten la transacción del menú. Documentar explícitamente el reemplazo completo o cambiarlo por actualización individual si es necesario conservar identificadores.

### 4. Reglas de mesa repetidas en reservas

Evidencia: `src/modules/mesa/mesa.service.ts` implementa `liberarEstadosVencidos`; `src/modules/reservas/reservas.service.ts:676` repite esa actualización como `liberarEstadosManualesVencidos`. Ambos servicios conocen directamente `mesa_bloqueo_horario` y reglas de cruces de horarios.

Propuesta: mantener estado temporal y persistencia de bloqueos en `mesa`, y disponibilidad/solapamiento de reservas en `reservas`. Compartir las reglas de intervalos que deban ser idénticas. Conservar bloqueos de filas y contexto transaccional para impedir dobles reservas.

## Otros puntos de organización

### 5. DTO de horarios y platos duplicados

- `src/modules/restaurante/dto/crear-restaurante.dto.ts:18` declara un `HorarioAtencionDto`, mientras `horario-atencion/dto/crear-horario-atencion.dto.ts` define otra versión con las mismas horas/día y su identificador de restaurante.
- `src/modules/menu/dto/crear-menu.dto.ts:14` declara `PlatoDetalleDto`, mientras `plato/dto/crear-plato.dto.ts` define el plato individual. La primera versión no tiene `IsNumber()` en precio y difiere en las reglas del nombre.

Propuesta: definir un DTO base del contenido del horario en `horario-atencion/dto` y uno del contenido del plato en `plato/dto`. Las operaciones anidadas e individuales deben reutilizarlos y añadir solo lo que corresponda a cada entrada. No reutilizar a ciegas DTO que exijan identificadores innecesarios para entradas anidadas.

### 6. Consultas y armado del restaurante repetidos

Evidencia: `restaurante.service.ts:92` y `:281` repiten consultas de ubicación, horarios, mesas, imágenes y reseñas, además del cálculo de calificación. La verificación de publicación repite parte de esas lecturas. Para N restaurantes, el listado hace una consulta inicial más cinco consultas por restaurante.

Propuesta: separar consultas de perfil/catálogo dentro de `restaurante`, cargar datos por lotes y calcular estadísticas de reseñas mediante agregación. Usar DTO de salida explícitos: hoy se devuelven entidades expandidas con `...rest`, incluyendo la relación `solicitud`, en vez de seleccionar solo el contrato de catálogo móvil. `listarPorUsuario` declara `Restaurante[]` aunque devuelve perfiles enriquecidos y termina forzando `any`.

Además, `listarPorUsuario` crea un restaurante y una asignación como reparación automática cuando no encuentra restaurantes. La lectura tiene efectos de escritura y esas dos escrituras no están dentro de una única transacción. Separar la reparación/provisión de la consulta y hacerla atómica e idempotente.

### 7. Consultas de acceso dentro del controlador de reservas

Evidencia: `src/modules/reservas/reservas.controller.ts:100` consulta roles y asignaciones directamente mediante `DataSource`.

Propuesta: que el controlador reciba entrada y delegue; llevar la decisión de acceso a un servicio compartido de autorización de restaurante. Las consultas propias de reservas pueden permanecer en su servicio o en un componente de consultas del mismo módulo.

### 8. Subida de imagen de plato dentro del controlador

Evidencia: `src/modules/plato/plato.controller.ts:43` valida el archivo, lo transforma y llama a Cloudinary. En restaurante esas operaciones están en el servicio.

Propuesta: mover la operación a un servicio de foto de plato o a `PlatoService`; dejar en el controlador los parámetros, la guarda y el interceptor de recepción.

### 9. Infraestructura compartida inicializada por separado

`auth/firebase-admin.service.ts` y `notificaciones/notificaciones.service.ts` inicializan o buscan la aplicación Firebase por separado. `RestauranteModule` y `PlatoModule` declaran cada uno `CloudinaryService` como proveedor.

Propuesta: módulo compartido de Firebase y módulo compartido de almacenamiento en `core`, exportando sus proveedores. Verificación de identidad sigue perteneciendo a autenticación; envío y contenido de avisos siguen perteneciendo a notificaciones. No es necesario mover la lógica de negocio a `core`.

En `categoria-soporte`, `onModuleInit` inserta categorías cuando la tabla está vacía. Para que la preparación de datos tenga un lugar claro, trasladar esa carga a un seed o migración controlada, preservando la inicialización requerida por entornos nuevos.

### 10. Tablas de apoyo solo visibles en migraciones y SQL

- `mesa_bloqueo_horario`: esquema en `migrations/20261001-mesa-bloqueos-horarios.sql`; escritura en mesa y lectura en reservas.
- `resena_creacion_control`: esquema en `migrations/20260920-resena-control.sql`; operación atómica en reseñas.

No es un error usar SQL sin entidad TypeORM. Para que sea fácil localizar todo, documentar estas tablas y encapsular su acceso en el módulo responsable. Añadir entidad solo si aporta valor. Mantener las migraciones SQL en una carpeta central permite ver su orden de aplicación.

Las migraciones también contienen restricciones e índices que las entidades no expresan: por ejemplo una ubicación por restaurante, una respuesta por reseña y orden válido de horas. Leer únicamente `*.entity.ts` no permite conocer todo el esquema real. No se comprobó qué migraciones están aplicadas en la base del usuario.

### 11. Regla de publicación aplicada de forma desigual

El catálogo de restaurante filtra perfiles publicables, pero las lecturas de `menu`, `plato`, `mesa`, `horario-atencion` y `ubicacion` no reutilizan esa comprobación. Ubicación permite lectura sin autenticación y los otros módulos mencionados permiten lectura a usuarios autenticados sin comprobar propiedad en esas rutas.

Esto no demuestra por sí solo que toda lectura deba restringirse: menús y horarios son datos del catálogo. Sí significa que no existe una regla compartida para decidir qué datos se muestran al cliente cuando un restaurante está incompleto o desactivado.

Propuesta: separar consultas del catálogo móvil y consultas de gestión, reutilizando una política explícita de visibilidad. Evitar volver a implementar `perfilPublicable` en cada carpeta.

## Qué ya está en su lugar

- Entidades y DTO principales se encuentran en sus módulos de negocio.
- Excepciones de horario están junto con los horarios, y tipos de comida junto con restaurante; ambas agrupaciones tienen sentido.
- El gateway de reservas está dentro de reservas.
- Notificaciones mantiene juntos su entidad, dispositivos, DTO, controlador y servicio, y reservas usa el servicio exportado.
- Configuración, guardas y almacenamiento compartidos están separados en `core`.
- Muchas consultas ya están correctamente en los servicios. No hace falta crear una carpeta `queries` ni una capa de repositorios propia para cada CRUD sencillo.
- Los cruces entre entidades de diferentes módulos son relaciones esperables del negocio; el problema es repetir reglas o escribir datos ajenos de varias formas.

## Organización sugerida

Mantener `src/modules/<modulo>` y añadir subdivisiones solo donde el tamaño lo justifique. Para restaurante:

```text
restaurante/
  restaurante.module.ts
  restaurante.controller.ts
  restaurante.service.ts
  restaurante.entity.ts
  tipo-comida.entity.ts
  dto/
  services/
    perfil-restaurante.service.ts
    publicacion-restaurante.service.ts
  queries/
    restaurante-consultas.ts
```

La consulta de catálogo puede combinar datos relacionados; la coordinación del perfil puede combinar escrituras. Ubicación, horarios, mesas, platos e imágenes conservan la implementación de sus reglas y operaciones. No crear todas estas carpetas por estética: extraer primero las responsabilidades efectivamente duplicadas.

## Verificación realizada

- Comprobación de tipos de producción: `tsc --noEmit --incremental false -p tsconfig.build.json`, correcta. No equivale a ejecutar la aplicación contra PostgreSQL.
- Suite Jest existente: **21 suites y 99 pruebas aprobadas**.
- Comprobación de tipos incluyendo archivos de prueba: `tsc --noEmit --incremental false -p tsconfig.json`, con errores. En el alcance destacan mocks mal tipados en `auth.security.spec.ts:137–144` y un constructor con seis argumentos donde se requieren siete en `reservas.disponibilidad.spec.ts:82`. También aparece un error en una prueba de solicitud, fuera del foco principal.
- No se ejecutaron pruebas E3 ni operaciones contra la base real, ni migraciones, ni envíos manuales de correo o push.

Que Jest pase no elimina los errores encontrados por la comprobación de tipos completa ni demuestra que los escenarios de asignaciones y persistencia real estén cubiertos.

## Orden recomendado para la siguiente etapa

1. Unificar acceso de restaurante entre HTTP y eventos; corregir el tipado de las pruebas del alcance.
2. Separar coordinación, publicación y consultas del perfil de restaurante; preservar sus contratos con Flutter y transacciones.
3. Unificar esquemas y operaciones compartidas de menú/plato y restaurante/horarios.
4. Centralizar estados y bloqueos de mesa usados por reservas; verificar concurrencia y límites de intervalos.
5. Ordenar proveedores Firebase/almacenamiento y contratos de salida; optimizar lecturas repetidas.

El objetivo es poder explicar con claridad dónde entra una petición, dónde se valida, qué servicio aplica las reglas y qué componente consulta o guarda cada dato. La base actual permite hacerlo sin reconstruir el backend completo.
