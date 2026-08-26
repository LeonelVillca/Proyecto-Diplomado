import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color de Mesa Chapaca — identidad valluna de Tarija.
class AppColors {
  AppColors._();

  static const Color wine = Color(0xFF6B1233);
  static const Color wineDark = Color(0xFF450B20);
  static const Color wineSoft = Color(0xFF8C3350);
  
  static const Color terracotta = Color(0xFFC1622E);
  static const Color gold = Color(0xFFC08A1E);
  static const Color sage = Color(0xFF5C7A52);

  static const Color paper = Color(0xFFF5EEE0);
  static const Color paperDeep = Color(0xFFEAE0C9);
  static const Color card = Color(0xFFFFFCF6);

  static const Color ink = Color(0xFF241512);
  static const Color inkSoft = Color(0xFF7A6A5C);

  static const Color line = Color(0x1A241512); // rgba(36,21,18,.10)
  
  // Compatibilidad hacia atrás (login screen y widgets viejos)
  static const Color background = paper;
  static const Color sunset = terracotta;
  static const Color secondaryText = inkSoft;
  
  static const Color onCard = Color(0xFF18181F);
  static const Color onCardMuted = Color(0xFF6B6B74);
  static const Color onScrimTitle = Color(0xFFFFFFFF);
  static const Color onScrimBody = Color(0xCCDFDAD3);
  static const Color googleInk = Color(0xFF3C4043);
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

    static List<BoxShadow> get sheet => const [
          BoxShadow(
            color: Color(0x1A450B20), // rgba(69,11,32,.10)
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ];

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

    static List<BoxShadow> get cardSoft => const [
          BoxShadow(
            color: Color(0x1A450B20), // rgba(69,11,32,.10)
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ];

    static List<BoxShadow> get cardStrong => const [
          BoxShadow(
            color: Color(0x596B1233), // rgba(107,18,51,.35)
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ];
  }

class AppFonts {
  AppFonts._();

  static const String display = 'Piazzolla';
  static const String body = 'Manrope';
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
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: InkSparkle.splashFactory,
    );

    final displayFont = GoogleFonts.piazzollaTextTheme(base.textTheme);
    final bodyFont = GoogleFonts.manropeTextTheme(displayFont);

    return base.copyWith(
      textTheme: bodyFont.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.wine,
        ),
        displayMedium: displayFont.displayMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.wine,
        ),
        headlineMedium: displayFont.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.ink,
        ),
        headlineSmall: displayFont.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.ink,
        ),
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.ink,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppColors.ink,
        ),
        titleSmall: bodyFont.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
        bodyLarge: bodyFont.bodyLarge?.copyWith(
          color: AppColors.ink,
          height: 1.5,
        ),
        bodyMedium: bodyFont.bodyMedium?.copyWith(
          color: AppColors.inkSoft,
          height: 1.5,
        ),
        bodySmall: bodyFont.bodySmall?.copyWith(
          color: AppColors.inkSoft,
          height: 1.45,
        ),
        labelLarge: bodyFont.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}