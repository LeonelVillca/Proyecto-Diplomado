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

## Checklist de módulos

- [x] 01. usuarios — entidad, DTOs, service, controller, module
- [ ] 02. rol — entidad, DTOs, service, controller, module
- [ ] 03. permiso — entidad, DTOs, service, controller, module
- [ ] 04. usuario_rol (tabla pivote: usuarios + rol) — entidad, DTOs, service, controller, module
- [ ] 05. rol_permiso (tabla pivote: rol + permiso) — entidad, DTOs, service, controller, module
- [ ] 06. cuentas_auth (login local: correo/contraseña) — entidad, DTOs, service, controller, module
- [ ] 07. oauth_cuenta (login Google) + MÓDULO AUTH COMPLETO (LocalStrategy, GoogleStrategy, JwtStrategy, login/register/callback Google, emisión de JWT) — entidad, DTOs, service, controller, module
- [ ] 08. solicitud — entidad, DTOs, service, controller, module
- [ ] 09. documento_adjunto — entidad, DTOs, service, controller, module
- [ ] 10. restaurante — entidad, DTOs, service, controller, module
- [ ] 11. ubicacion — entidad, DTOs, service, controller, module
- [ ] 12. horario_atencion — entidad, DTOs, service, controller, module
- [ ] 13. mesa — entidad, DTOs, service, controller, module
- [ ] 14. menu — entidad, DTOs, service, controller, module
- [ ] 15. plato — entidad, DTOs, service, controller, module
- [ ] 16. imagen — entidad, DTOs, service, controller, module
- [ ] 17. reservas (incluye Gateway de WebSocket) — entidad, DTOs, service, controller, module
- [ ] 18. resenas — entidad, DTOs, service, controller, module
- [ ] 19. respuesta_resena — entidad, DTOs, service, controller, module
- [ ] 20. categoria_soporte — entidad, DTOs, service, controller, module
- [ ] 21. soporte — entidad, DTOs, service, controller, module
- [ ] 22. reportes — entidad, DTOs, service, controller, module
- [ ] 23. notificacion — entidad, DTOs, service, controller, module
- [ ] 24. visita — entidad, DTOs, service, controller, module

> Pendientes fuera de este ciclo: módulo de promoción y vista `vista_ranking_restaurantes` (se agregan más adelante, aún no existen en la base de datos actual).

## Notas y decisiones tomadas

- Módulo 01 (usuarios): la entidad mapea a la tabla `usuarios` con `synchronize: false` (ya se dejó `DB_SYNCHRONIZE=false` en `.env` y se fijó en `false` en `database.config.ts`). Endpoints CRUD básicos sin guards de rol, porque la infraestructura de autenticación y roles (JwtStrategy, RolesGuard, decoradores `@Roles`, `@Public`) se construye recién en el paso 07. Cuando exista, se aplican los guards a los endpoints que requieran `Admin_Sistema` (listar, asignar roles, gestionar estado/eliminar usuarios).