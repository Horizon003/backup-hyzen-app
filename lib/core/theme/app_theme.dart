import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

class AppTheme {
  AppTheme._();
  static const fontFamily = 'Manrope';

  static TextTheme _text(Color ink, Color ink2) {
    const f = fontFamily;
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: f,
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontFamily: f,
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: f,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontFamily: f,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: f,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: f,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: f,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: f,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: ink2,
      ),
      bodySmall: TextStyle(
        fontFamily: f,
        fontSize: 12.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: ink2,
      ),
      labelLarge: TextStyle(
        fontFamily: f,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: f,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ink2,
      ),
      labelSmall: TextStyle(
        fontFamily: f,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: ink2,
        letterSpacing: 0.6,
      ),
    );
  }

  static ThemeData light([Color seed = HColors.primary]) =>
      _build(Brightness.light, seed);
  static ThemeData dark([Color seed = HColors.primary]) =>
      _build(Brightness.dark, seed);

  static ThemeData _build(Brightness b, Color seed) {
    final dark = b == Brightness.dark;
    final ink = dark ? HColors.darkInk : HColors.ink;
    final ink2 = dark ? HColors.darkInk2 : HColors.ink2;
    final bg = dark ? HColors.darkBackground : HColors.background;
    final surface = dark ? HColors.darkSurface : HColors.surface;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b)
        .copyWith(
          primary: dark
              ? ColorScheme.fromSeed(seedColor: seed, brightness: b).primary
              : seed,
          onPrimary: dark ? const Color(0xFF25133F) : Colors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: ink2,
          error: HColors.error,
          outline: dark ? const Color(0x33FFFFFF) : HColors.outlineStrong,
          outlineVariant: dark ? const Color(0x1FFFFFFF) : HColors.outline,
        );
    final text = _text(ink, ink2);
    final border = OutlineInputBorder(
      borderRadius: HRadius.all(HRadius.md),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: ink,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HRadius.all(HRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? HColors.darkSurfaceAlt : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: HColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: HColors.error, width: 1.6),
        ),
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        hintStyle: text.bodyMedium?.copyWith(
          color: dark ? HColors.darkInk2 : HColors.ink3,
        ),
        errorStyle: text.bodySmall?.copyWith(
          color: HColors.error,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: ink2,
        suffixIconColor: ink2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: ink,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: dark ? const Color(0xFF4D2D73) : HColors.primarySoft,
        checkmarkColor: dark ? const Color(0xFFD8BFFF) : HColors.primary,
        labelStyle: text.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.pill)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? scheme.primary : ink2,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 27,
            color: s.contains(WidgetState.selected) ? scheme.primary : ink2,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: dark
              ? HColors.darkSurfaceAlt
              : const Color(0xFFF7F5FA),
          foregroundColor: ink2,
          minimumSize: const Size(42, 42),
          shape: const CircleBorder(),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: HColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.md)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
