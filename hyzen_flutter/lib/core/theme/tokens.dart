import 'package:flutter/material.dart';

/// PHARM D WITH HYZEN design tokens (approved Q02 / Q31 design system).
///
/// Premium-academic, minimal-professional palette:
///   Deep Teal  #087F76  – brand / primary actions
///   Slate      #1A3440  – ink, premium dark hero surfaces
///   Background #F3F8F7  – calm light canvas
///   Pale teal  #DDEDEA  – soft containers / chips
///   Muted text #507379  – secondary copy
class HColors {
  HColors._();
  // Brand
  static const primary = Color(0xFF087F76);
  static const primaryDeep = Color(0xFF06655E);
  static const primarySoft = Color(0xFFDDEDEA);
  static const slate = Color(0xFF1A3440);
  static const slateDeep = Color(0xFF12262F);
  static const teal = Color(0xFF087F76);
  static const mint = Color(0xFF5FD1C1);
  static const onPrimary = Colors.white;

  // Ink
  static const ink = Color(0xFF1A3440);
  static const ink2 = Color(0xFF507379);
  static const ink3 = Color(0xFF7E9A9E);

  // Surfaces (light)
  static const background = Color(0xFFF3F8F7);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFE9F3F1);
  static const outline = Color(0xFFE1ECEA);
  static const outlineStrong = Color(0xFFC6D9D6);

  // Status
  static const success = Color(0xFF15885A);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF2B6F9E);

  // Dark
  static const darkBackground = Color(0xFF0D1B21);
  static const darkSurface = Color(0xFF152A33);
  static const darkSurfaceAlt = Color(0xFF1D3540);
  static const darkInk = Color(0xFFEAF4F2);
  static const darkInk2 = Color(0xFFA5C2C3);
  static const darkPrimary = Color(0xFF4CC3B5);

  /// Restrained module accents – used on small icon badges only.
  static const notes = Color(0xFF087F76);
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
    BoxShadow(color: Color(0x0D1A3440), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const lifted = [
    BoxShadow(color: Color(0x161A3440), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x26087F76), blurRadius: 22, offset: Offset(0, 8)),
  ];
}

/// Premium dark Slate → Deep Teal hero gradient (Q31 D – selected screens only).
const hSlateGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A3440), Color(0xFF0F4A4D), Color(0xFF087F76)],
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
