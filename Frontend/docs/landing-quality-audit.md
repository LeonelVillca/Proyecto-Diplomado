# Auditoría de la landing — Mesa Chapaca

Fecha de línea base: 2026-09-14  
Alcance: landing pública web en Flutter (`AdminLandingScreen`)  
Condiciones: inspección de fuente local. No hay una URL pública confirmada ni datos CrUX/Search Console; por tanto, LCP, INP y CLS se tratan como riesgos de implementación, no como métricas de campo.

## Evaluación inicial

### Arquitectura detectada

- Flutter 3.44 / Dart 3.12 según `pubspec.lock`.
- Entrada web: `lib/main_web.dart` → `AppWeb` → `AdminLandingScreen`.
- La landing se divide en `landing_navbar.dart`, `landing_hero.dart`, `landing_benefits.dart` y `landing_footer.dart`.
- Backend NestJS independiente; la mejora no requiere cambiarlo.
- Identidad existente: vino, dorado y tonos de papel; fuentes Bodoni Moda y Karla ya incluidas localmente.

### Línea base

| Área | Estado inicial | Evidencia |
|---|---|---|
| Responsive | Alto riesgo | Hero, pasos, beneficios, testimonios, estadísticas y footer usan filas rígidas con paddings de 60–80 px, sin breakpoints. |
| Accesibilidad | Alto riesgo | Enlaces hechos con `GestureDetector`/texto, controles sociales no accionables, semántica y foco insuficientes, sin enlace para saltar al contenido. |
| Navegación | Alto riesgo | Los enlaces del navbar no desplazan a secciones y varios CTA usan callbacks vacíos. |
| Movimiento | Riesgo medio | Animación de entrada siempre activa; no consulta `MediaQuery.disableAnimations` ni la preferencia de movimiento reducido. |
| LCP | Riesgo alto (fuente) | Imagen hero PNG de 733 KB; inicialización de Firebase y restauración de sesión bloquean `runApp`; Google Fonts añade solicitudes remotas aunque existen fuentes locales. |
| INP | Riesgo medio (fuente) | Varios widgets con estado individual para hover y filtros de desenfoque costosos; no hay medición de interacción en navegador. |
| CLS | Riesgo medio (fuente) | La UI Flutter reserva tamaños en varios recursos, pero la pantalla queda vacía hasta arrancar el motor; no existe shell HTML con espacio y contenido inicial. |
| SEO técnico | Crítico | Título, descripción, nombre PWA y colores son los valores genéricos de Flutter; faltan canonical, robots, sitemap, Open Graph y JSON-LD. |
| Recursos | Alto riesgo | El paquete declara imágenes de hasta 4.0 MB y depende de `google_fonts`; el script de Google Maps se carga en toda la landing. |
| Calidad | Pendiente | `flutter analyze` no produjo salida y se interrumpió tras 120 s; se repetirá con el proyecto modificado. |

## Dirección de diseño aprobada para implementación

### Tokens

- Tinta de uva `#2A1020`: títulos y superficies profundas.
- Vino reserva `#6B1233`: acción principal y señal de marca.
- Oro vid `#B98324`: acentos con contraste controlado.
- Papel valle `#F7F1E7`: fondo principal.
- Piedra cálida `#E7DDCC`: secciones y divisores.
- Hoja `#466447`: estados positivos y detalles.

Tipografía: Bodoni Moda local para titulares editoriales; Karla local para cuerpo, navegación y controles. Alineación principalmente izquierda; centrado solo donde refuerza una secuencia o cifras.

### Layout

```text
Móvil                 Tablet                    Escritorio
┌──────────────┐       ┌──────────────────┐      ┌──────────────────────────┐
│ marca   menú │       │ marca       CTA  │      │ marca  navegación   CTA │
│ mensaje      │       │ mensaje  visual  │      │ mensaje      visual     │
│ CTA          │       │ CTA       prueba │      │ prueba       reserva    │
│ visual       │       │ pasos en 2 cols  │      │ pasos en 3 columnas     │
│ secciones 1c │       │ secciones 2 cols │      │ bloque editorial 2 cols │
└──────────────┘       └──────────────────┘      └──────────────────────────┘
```

Principios: una sola pieza memorable (la composición hero inspirada en una mesa/reserva), información progresiva, bordes y numeración solo con función, controles táctiles de al menos 48 px, animación breve y cancelable, y nada que dependa exclusivamente del hover.

## Verificación posterior

### Resultado

| Área | Antes | Después verificado |
|---|---|---|
| Responsive | Filas rígidas, sin breakpoints | `LayoutBuilder` + `Wrap`; inspección visual a 375, 768 y 1440 px. A 768 px, `scrollWidth` y `clientWidth` son 768 px. |
| Navegación | Enlaces y CTA sin acción | Beneficios, proceso, restaurantes y contacto desplazan a su sección; acceso y registro conservan las rutas existentes. |
| Accesibilidad | Gestos personalizados y semántica incompleta | Botones Material con teclado/foco, objetivos de 48 px, encabezados e imágenes etiquetados, lectura agrupada y skip link HTML. |
| Movimiento | Entrada obligatoria de 900 ms | Una entrada de 560 ms con `transform`/opacidad; estado final inmediato cuando `MediaQuery.disableAnimations` está activo. |
| Imágenes de landing | 733.117 B + 1.124.950 B | 139.398 B + 295.462 B: reducción combinada de 76,6 %. Dimensión visual reservada con `AspectRatio`. |
| Fuentes | `GoogleFonts` en la landing, con riesgo de solicitudes externas | Bodoni Moda y Karla servidas desde los assets locales ya existentes. |
| HTML inicial | Pantalla vacía hasta iniciar Flutter | Shell crítico HTML/CSS con H1, texto, CTA y espacio 1:1 reservado para la imagen; se retira cuando carga Flutter. |
| SEO | Valores genéricos de Flutter | Título, descripción, `es-BO`, canonical, robots meta/archivo, sitemap, Open Graph, Twitter Card y `SoftwareApplication` JSON-LD. |
| Compilación | No medida | `flutter build web --release --target lib/main_web.dart`: correcta. `main.dart.js`: 3.784.667 B; iconos reducidos 98–99 % por tree-shaking. |
| Pruebas | No medidas | `flutter test`: no ejecutable porque el repositorio no contiene el directorio `Frontend/test`. |
| Análisis | Comando inicial bloqueado por la caché del SDK | Los archivos nuevos/modificados de landing no reportan errores. Persisten advertencias preexistentes fuera del alcance de la landing. |

### Verificación manual pendiente

- Confirmar si `https://resttarija.web.app/` será el dominio canónico definitivo; actualizar canonical, OG y sitemap si se usará un dominio propio.
- Validar datos reales de testimonios, métricas y correo `contacto@mesachapaca.bo` antes de publicar.
- Ejecutar Lighthouse/DevTools y revisar CrUX o Search Console sobre producción. La inspección local permite confirmar riesgos corregidos, no afirmar mejoras de p75 en LCP, INP o CLS.
- Probar VoiceOver/NVDA y zoom de texto al 200 %; el árbol semántico del navegador expone navegación, H2, botones e imágenes, pero una prueba humana sigue siendo necesaria.
- Revisar el peso global de la aplicación (52,4 MB de artefactos, incluyendo assets de pantallas ajenas a la landing) y considerar división por experiencia web/móvil en una fase separada.
