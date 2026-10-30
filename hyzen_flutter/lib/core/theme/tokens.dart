import 'package:flutter/material.dart';

/// PHARM D WITH HYZEN design tokens.
///
/// Graphite is the quiet product foundation. The selected palette is reserved
/// for primary actions, status, and small category accents.
class HColors {
  HColors._();
  // Brand
  static const primary = Color(0xFF1C1C1E);
  static const primaryDeep = Color(0xFF000000);
  static const primarySoft = Color(0xFFE8E8E6);
  static const slate = Color(0xFF252525);
  static const slateDeep = Color(0xFF111111);
  static const teal = Color(0xFF087F76);
  static const mint = Color(0xFF5FD1C1);
  static const onPrimary = Colors.white;

  // Ink
  static const ink = Color(0xFF1C1C1E);
  static const ink2 = Color(0xFF626262);
  static const ink3 = Color(0xFF8C8C8C);

  // Surfaces (light)
  static const background = Color(0xFFF6F6F4);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEDEDEB);
  static const outline = Color(0xFFE2E2E0);
  static const outlineStrong = Color(0xFFCACAC7);

  // Status
  static const success = Color(0xFF15885A);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF2B6F9E);

  // Dark
  static const darkBackground = Color(0xFF101010);
  static const darkSurface = Color(0xFF1C1C1C);
  static const darkSurfaceAlt = Color(0xFF292929);
  static const darkInk = Color(0xFFF5F5F3);
  static const darkInk2 = Color(0xFFB4B4B0);
  static const darkPrimary = Color(0xFFF2F2F0);

  /// Restrained module accents – used on small icon badges only.
  static const notes = Color(0xFF1C1C1E);
  static const mcqs = Color(0xFF2B6F9E);
  static const papers = Color(0xFF3F7D4E);
  static const special = Color(0xFFB0702A);
  static const lectures = Color(0xFF8A4E6B);
}

/// 8-point rhythm.
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
  static const screen = 20.0;
}

class HRadius {
  HRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class HMotion {
  HMotion._();
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;
}

class HShadow {
  HShadow._();
  static const soft = [
    BoxShadow(color: Color(0x0D1A1A1A), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const lifted = [
    BoxShadow(color: Color(0x161A1A1A), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x261C1C1E), blurRadius: 22, offset: Offset(0, 8)),
  ];
}

/// Quiet graphite hero gradient for selected surfaces only.
const hSlateGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF111111), Color(0xFF292929), Color(0xFF4A4A4A)],
  stops: [0, .62, 1],
);

/// Keep module colours legible on both opaque surface themes.
Color adaptiveAccent(BuildContext context, Color color) {
  final theme = Theme.of(context);
  if (color == HColors.primary ||
      color == HColors.primaryDeep ||
      color == HColors.notes) {
    return theme.colorScheme.primary;
  }
  if (color == HColors.primarySoft) return theme.colorScheme.primaryContainer;
  if (theme.brightness != Brightness.dark) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(hsl.lightness < 0.68 ? 0.68 : hsl.lightness)
      .toColor();
}
