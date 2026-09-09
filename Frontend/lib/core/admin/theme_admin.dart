import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Colores principales (paleta Mesa Chapaca)
  static const Color primaryColor = Color(0xFF6E1E39); // Guindo/Vino tinto
  static const Color primaryDark = Color(0xFF4A1325);
  static const Color primaryLight = Color(0xFF8B2648);
  static const Color accentColor = Color(0xFFD4AF37); // Dorado sutil

  // Fondos y superficies
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF0F2F5);

  // Textos
  static const Color textDark = Color(0xFF1E1B1A);
  static const Color textMuted = Color(0xFF6B635E);
  static const Color textLight = Color(0xFFA39C98);

  // Bordes y separadores
  static const Color border = Color(0xFFE2E8F0);

  // Estilos de texto comunes
  static TextStyle titleStyle = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static TextStyle subtitleStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 14,
    color: textMuted,
  );
}


