import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color de Mesa Chapaca — identidad valluna de Tarija.
class AppColors {
  AppColors._();

  /// Fondo crema cálido (viñedo, papel añejo). No blanco puro.
  static const Color background = Color(0xFFF7F1E6);

  /// Superficie elevada: papel más claro con calidez.
  static const Color paper = Color(0xFFFDF8EE);

  /// Vino tinto profundo — acento principal.
  static const Color wine = Color(0xFF5C1A2E);

  /// Dorado mostaza — hoja de parra seca / uva madura.
  static const Color gold = Color(0xFF8B6F3E);

  /// Naranja atardecer — cima del degradado de la escena de bienvenida.
  static const Color sunset = Color(0xFFC97B3D);

  /// Texto principal: casi negro con calidez.
  static const Color ink = Color(0xFF2B211C);

  /// Texto secundario.
  static const Color secondaryText = Color(0xFF7A6F63);

  // ---------------------------------------------------------------
  // UI inmersiona para la pantalla de login (foto + tarjeta blanca).
  // ---------------------------------------------------------------

  /// Tinta moderna sobre la tarjeta blanca (casi negro, frío y limpio).
  static const Color onCard = Color(0xFF18181F);

  /// Gris para texto secundario dentro de la tarjeta.
  static const Color onCardMuted = Color(0xFF6B6B74);

  /// Título sobre la foto: blanco puro.
  static const Color onScrimTitle = Color(0xFFFFFFFF);

  /// Subtítulo sobre la foto: gris claro translúcido.
  static const Color onScrimBody = Color(0xCCDFDAD3);

  /// Gris oficial de texto del botón de Google.
  static const Color googleInk = Color(0xFF3C4043);

  /// Separadores / bordes suaves.
  static const Color hairline = Color(0x1A000000);
}

/// Degradados reutilizables de la pantalla de bienvenida.
class AppGradients {
  AppGradients._();

  /// Scrim negro sobre la foto: 38% arriba → 92% abajo.
  /// Es lo que hace resaltar el branding y la tarjeta blanca.
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x61000000), Color(0xEB000000)],
    stops: [0.0, 1.0],
  );

  /// Viñeta sutil en los bordes para dirigir la mirada al centro.
  static const RadialGradient vignette = RadialGradient(
    center: Alignment(0.0, -0.15),
    radius: 1.35,
    colors: [Colors.transparent, Color(0x40000000)],
    stops: [0.55, 1.0],
  );
}

/// Sombras en capas para dar profundidad "material 3" sin planitud.
  class AppShadows {
    AppShadows._();

    /// Sombra de la tarjeta inferior sobre la foto.
    static List<BoxShadow> get sheet => const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ];

    /// Sombra suave del botón de Google sobre la tarjeta blanca.
    static List<BoxShadow> get googleButton => const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ];

    /// Sombra ligera para tarjetas compactas y chips.
    static List<BoxShadow> get cardSoft => const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ];

    /// Sombra más marcada para tarjetas grandes destacadas.
    static List<BoxShadow> get cardStrong => const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ];
  }

/// Pareja tipográfica moderna de Mesa Chapaca (vía Google Fonts).
class AppFonts {
  AppFonts._();

  /// Display geométrica moderna — títulos y botones.
  static const String display = 'Montserrat';

  /// Sans-serif humanista y aireada — cuerpo y subtítulos.
  static const String body = 'Poppins';
}

/// Tema global de la aplicación.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wine,
        primary: AppColors.wine,
        onPrimary: Colors.white,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
    );

    // Tipografía moderna vía Google Fonts (fallback offline: fuente del sistema).
    final montserrat = GoogleFonts.montserratTextTheme(base.textTheme);
    final poppins =
        GoogleFonts.poppinsTextTheme(GoogleFonts.montserratTextTheme());

    return base.copyWith(
      textTheme: poppins.copyWith(
        displayLarge: montserrat.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.wine,
        ),
        displayMedium: montserrat.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.wine,
        ),
        headlineMedium: montserrat.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        headlineSmall: montserrat.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: montserrat.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: montserrat.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleSmall: poppins.titleSmall?.copyWith(
          fontSize: 12,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
        bodyLarge: poppins.bodyLarge?.copyWith(
          color: AppColors.ink,
          height: 1.5,
        ),
        bodyMedium: poppins.bodyMedium?.copyWith(
          color: AppColors.secondaryText,
          height: 1.5,
        ),
        bodySmall: poppins.bodySmall?.copyWith(
          color: AppColors.secondaryText,
          height: 1.45,
        ),
        labelLarge: montserrat.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}