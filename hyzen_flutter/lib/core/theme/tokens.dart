import 'package:flutter/material.dart';

/// Hyzen V3 design tokens. All screens must use these instead of literals.
/// Purple reference design system; secondary accents identify library categories.
class HColors {
  HColors._();
  // Brand
  static const primary = Color(0xFF7C3AED);
  static const primaryDeep = Color(0xFF5222A6);
  static const primarySoft = Color(0xFFF0E7FF);
  static const teal = Color(0xFF177C90);
  static const onPrimary = Colors.white;

  // Ink (deep navy)
  static const ink = Color(0xFF15112E);
  static const ink2 = Color(0xFF4A5B6E);
  static const ink3 = Color(0xFF7D8B9A);

  // Surfaces (light)
  static const background = Color(0xFFFCFAFF);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF5EFFF);
  static const outline = Color(0x0A4F327D);
  static const outlineStrong = Color(0x2E0E1B2C);

  // Status
  static const success = Color(0xFF13854F);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF246FA8);

  // Dark
  static const darkBackground = Color(0xFF100B1F);
  static const darkSurface = Color(0xFF211935);
  static const darkSurfaceAlt = Color(0xFF302348);
  static const darkInk = Color(0xFFFAF7FF);
  static const darkInk2 = Color(0xFFD3C9E3);

  /// Module accent hues (used sparingly on icons only).
  static const notes = Color(0xFF7C3AED);
  static const mcqs = Color(0xFF246FA8);
  static const papers = Color(0xFF179867);
  static const special = Color(0xFFD47A22);
  static const lectures = Color(0xFFAD5575);
}

class HSpace {
  HSpace._();
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const screen = 20.0; // horizontal screen padding
}

class HRadius {
  HRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class HMotion {
  HMotion._();
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

class HShadow {
  HShadow._();
  static const soft = [
    BoxShadow(color: Color(0x0F0E1B2C), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const lifted = [
    BoxShadow(color: Color(0x1A0E1B2C), blurRadius: 30, offset: Offset(0, 12)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x227C3AED), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

/// Keep module colours legible on both opaque surface themes.
Color adaptiveAccent(BuildContext context, Color color) {
  final theme = Theme.of(context);
  if (color == HColors.primary || color == HColors.primaryDeep || color == HColors.notes) return theme.colorScheme.primary;
  if (color == HColors.primarySoft) return theme.colorScheme.primaryContainer;
  if (theme.brightness != Brightness.dark) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(hsl.lightness < 0.70 ? 0.70 : hsl.lightness)
      .toColor();
}
