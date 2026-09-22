import 'package:flutter/material.dart';

/// Tokens visuales exclusivos del panel administrativo web.
/// La lógica de cada pantalla permanece fuera de esta capa.
abstract final class AdminTheme {
  static const Color primaryColor = Color(0xFFBE4B24);
  static const Color primaryDark = Color(0xFF9E3A18);
  static const Color primaryLight = Color(0xFFF8E7DC);
  static const Color accentColor = Color(0xFF55684B);
  static const Color accentSoft = Color(0xFFE7EDDF);
  static const Color gold = Color(0xFFC08A2D);

  static const Color background = Color(0xFFFAF5EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F1E5);
  static const Color rowHover = Color(0xFFFCF7EE);

  static const Color textDark = Color(0xFF26201A);
  static const Color textMuted = Color(0xFF6F6259);
  static const Color textLight = Color(0xFFA99D91);
  static const Color border = Color(0xFFEAE1D3);
  static const Color rowBorder = Color(0xFFF1EADD);

  static const Color success = Color(0xFF1F7A4D);
  static const Color successSoft = Color(0xFFE3F1E8);
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningSoft = Color(0xFFFBF0D9);
  static const Color error = Color(0xFFC0341B);
  static const Color errorSoft = Color(0xFFFBE9E4);

  static const Color sidebar = Color(0xFF241D16);
  static const Color sidebarText = Color(0x9EFDF4EE);
  static const Color sidebarActiveText = Color(0xFFFDF4EE);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0F26201A), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x1A26201A), blurRadius: 34, offset: Offset(0, 12)),
  ];

  static TextStyle get titleStyle => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.1,
        color: textDark,
      );

  static TextStyle get subtitleStyle => const TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: 14,
        height: 1.5,
        color: textMuted,
      );

  static ThemeData get webTheme {
    final base = ThemeData(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      surface: surface,
      error: error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(fontFamily: 'InstrumentSans').copyWith(
            headlineLarge: titleStyle,
            titleLarge: titleStyle,
            titleMedium: subtitleStyle,
            bodyMedium: bodyStyle,
            bodySmall: bodyStyle.copyWith(fontSize: 12),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: bodyStyle.copyWith(color: textLight),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: const OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      dividerTheme: const DividerThemeData(color: rowBorder, thickness: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: textDark, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
