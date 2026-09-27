import 'package:flutter/material.dart';

/// Identidad visual del comensal. Se aplica después de iniciar sesión para
/// conservar intacta la pantalla de bienvenida y su tema.
class ConsumerColors {
  ConsumerColors._();

  static const paper = Color(0xFFFAF5EC);
  static const background = paper;
  static const card = Color(0xFFFFFFFF);
  static const paperDeep = Color(0xFFF1EADD);
  static const ink = Color(0xFF26201A);
  static const inkSoft = Color(0xFF6F6259);
  static const secondaryText = inkSoft;
  static const wine = Color(0xFFBE4B24);
  static const wineDark = Color(0xFF9E3A18);
  static const wineSoft = Color(0xFFF8E7DC);
  static const terracotta = wine;
  static const sunset = wine;
  static const gold = Color(0xFFC08A2D);
  static const sage = Color(0xFF55684B);
  static const success = Color(0xFF1F7A4D);
  static const successSoft = Color(0xFFE3F1E8);
  static const warning = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFFBF0D9);
  static const error = Color(0xFFC0341B);
  static const errorSoft = Color(0xFFFBE9E4);
  static const line = Color(0xFFEAE1D3);
  static const hairline = Color(0xFFF1EADD);
}

class ConsumerShadows {
  ConsumerShadows._();

  static const cardSoft = [
    BoxShadow(color: Color(0x0F26201A), blurRadius: 10, offset: Offset(0, 2)),
  ];
  static const cardStrong = [
    BoxShadow(color: Color(0x1A26201A), blurRadius: 34, offset: Offset(0, 12)),
  ];
}

class ConsumerTheme {
  ConsumerTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ConsumerColors.paper,
      colorScheme: const ColorScheme.light(
        primary: ConsumerColors.wine,
        onPrimary: Colors.white,
        secondary: ConsumerColors.sage,
        surface: ConsumerColors.paper,
        onSurface: ConsumerColors.ink,
        error: ConsumerColors.error,
      ),
      fontFamily: 'InstrumentSans',
      appBarTheme: const AppBarTheme(
        backgroundColor: ConsumerColors.paper,
        foregroundColor: ConsumerColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ConsumerColors.wine,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ConsumerColors.wineDark,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: ConsumerColors.wine),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ConsumerColors.card,
        hintStyle: const TextStyle(color: Color(0xFFB8ADA2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ConsumerColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ConsumerColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ConsumerColors.wine, width: 1.5),
        ),
      ),
    );
    final body = base.textTheme.apply(
      fontFamily: 'InstrumentSans',
      bodyColor: ConsumerColors.ink,
      displayColor: ConsumerColors.ink,
    );
    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
        displayMedium: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 29,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: ConsumerColors.ink,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ConsumerColors.ink,
        ),
        titleSmall: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ConsumerColors.inkSoft,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 16,
          color: ConsumerColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 14,
          color: ConsumerColors.inkSoft,
        ),
        bodySmall: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 12,
          color: ConsumerColors.inkSoft,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ConsumerColors.ink,
        ),
      ),
    );
  }
}
