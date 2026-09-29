<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Despliegue de Mesa Chapaca

1. Configura las variables de `.env.example` en el proveedor (sin subir el archivo real al repositorio). En producción son obligatorios `NODE_ENV=production`, `FRONTEND_URL`, `API_PUBLIC_URL` y `CORS_ORIGINS` con HTTPS; también los secretos JWT/PIN, PostgreSQL, SMTP y Firebase. `API_PUBLIC_URL` debe ser el origen público del backend para los enlaces de confirmación. Activa `DB_SSL=true` si PostgreSQL exige TLS.
2. Usa almacenamiento **persistente** para `Backend/storage`. En un alojamiento gratuito con disco efímero se perderían documentos e imágenes al reiniciar o redesplegar; si no ofrece un volumen persistente, hay que integrar almacenamiento externo antes de guardar datos reales.
3. Rota las credenciales anteriormente expuestas y la contraseña del administrador. No ejecutes `npm run seed` contra la base real.
4. Tras hacer una copia de seguridad de la base, ejecuta `node scripts/apply-security-migration.cjs --apply`. La migración añade protección de sesiones, reservas duplicadas, control de reseñas y confirmación de correo; si encuentra datos incompatibles, detente y resuélvelos antes de continuar.
5. Para desplegar el catálogo de tipos de comida, después de la migración de seguridad ejecuta `node scripts/apply-security-migration.cjs --tipos-comida --apply`. La migración crea el catálogo, asigna categorías reconocibles y deja los valores ambiguos como “Por definir” para editarlos desde el perfil.
6. Para fijar las reservas a una hora y aplicar el margen previo de disponibilidad, ejecuta `node scripts/apply-security-migration.cjs --reserva-horario --apply`. Haz antes una copia de seguridad; la migración aborta si encuentra reservas activas incompatibles y estandariza las duraciones existentes a 60 minutos.
7. Ejecuta `npm run build`, luego `npm run preflight:prod` (solo lectura) y finalmente `npm run start:prod`.
8. Compila Flutter con `--dart-define=API_BASE_URL=https://TU_BACKEND`; una build de producción no acepta HTTP ni una URL vacía.

El formulario público requiere confirmar el correo antes de aprobar una solicitud. El enlace vence en 24 horas y puede reenviarse. La app limita envíos por IP, pero en una publicación abierta aún conviene añadir defensa contra abuso distribuido. Prueba los flujos con datos de prueba y vigila los registros tras el despliegue.

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
