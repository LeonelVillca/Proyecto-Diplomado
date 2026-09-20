import 'package:flutter/material.dart';

abstract final class LandingPalette {
  static const ink = Color(0xFF2A1020);
  static const wine = Color(0xFF6B1233);
  static const wineHover = Color(0xFF842344);
  static const wineDeep = Color(0xFF310916);
  static const gold = Color(0xFFB98324);
  static const terracotta = Color(0xFFC45B3C);
  static const sun = Color(0xFFE7A84B);
  static const leafSoft = Color(0xFFE4EEE3);
  static const paper = Color(0xFFF7F1E7);
  static const paperDeep = Color(0xFFE7DDCC);
  static const card = Color(0xFFFFFCF7);
  static const leaf = Color(0xFF466447);
  static const muted = Color(0xFF6E5F55);
  static const line = Color(0x332A1020);
}

abstract final class LandingType {
  static const display = 'Karla';
  static const body = 'Karla';

  static TextStyle heading({
    double size = 40,
    Color color = LandingPalette.ink,
    FontWeight weight = FontWeight.w700,
    double height = 1.06,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: -1.15,
  );

  static TextStyle bodyText({
    double size = 16,
    Color color = LandingPalette.muted,
    FontWeight weight = FontWeight.w400,
    double height = 1.55,
  }) => TextStyle(
    fontFamily: body,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );
}

abstract final class LandingLayout {
  static const maxWidth = 1180.0;
  static const tablet = 760.0;
  static const desktop = 1040.0;

  static double horizontalPadding(double width) {
    if (width >= desktop) return 56;
    if (width >= tablet) return 32;
    return 20;
  }

  static double sectionPadding(double width) {
    if (width >= desktop) return 96;
    if (width >= tablet) return 72;
    return 56;
  }
}

class SectionMarker extends StatelessWidget {
  const SectionMarker(this.text, {this.onDark = false, super.key});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 2, color: LandingPalette.gold),
        const SizedBox(width: 10),
        Text(
          text,
          style: LandingType.bodyText(
            size: 14,
            weight: FontWeight.w700,
            color: onDark ? LandingPalette.paper : LandingPalette.wine,
          ),
        ),
      ],
    );
  }
}
