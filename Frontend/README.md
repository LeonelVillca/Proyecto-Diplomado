# frontend

A new Flutter project.

## Cómo probar en dispositivo físico

Para probar la app en un celular físico conectado a la misma red WiFi que la PC de desarrollo:

1. **Define el entorno** en `lib/core/network/api_endpoints.dart`: cambia `ApiEndpoints.currentEnv` según el caso
   (`Environment.emulador`, `Environment.dispositivoFisico` o `Environment.produccion`). En `dispositivoFisico`
   asegúrate de que la IP sea la IP WiFi actual de tu PC (averíguala con `ipconfig`).
2. **Misma red WiFi**: el celular y la PC deben estar conectados a la misma red.
3. **Backend accesible**: el backend de NestJS ya escucha en `0.0.0.0` (todas las interfaces) con CORS habilitado,
   así que solo necesitas que el puerto 3000 esté libre.

> **Ojo con redes institucionales/universitarias**: si la red tiene aislamiento de clientes (AP Isolation), el
> celular verá la interfaz de la app pero **no podrá conectarse al backend** sin importar la configuración.
> En ese caso usa `ngrok http 3000` para exponer el backend con una URL pública temporal y pon esa URL en
> `ApiEndpoints.baseUrl`, o prueba desde una red doméstica/hotspot personal.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
