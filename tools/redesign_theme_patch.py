# Applies the 1.5 theme + shared widget polish. Idempotent-ish: run once on 1.4.3 source.
from pathlib import Path
R=Path(__file__).resolve().parent.parent/'hyzen_flutter'
def sub(path, old, new, required=True):
    p=R/path; s=p.read_text()
    if old not in s:
        if required: raise SystemExit(f'pattern missing in {path}: {old[:60]!r}')
        return
    p.write_text(s.replace(old,new))

p=R/'lib/core/theme/app_theme.dart'; s=p.read_text()
start=s.index('  static ThemeData light(')
end=s.index('    final text = _text(ink, ink2);')
s=s[:start]+'''  static ThemeData light([Color seed = HColors.primary]) =>
      _build(Brightness.light, seed);
  static ThemeData dark([Color seed = HColors.primary]) =>
      _build(Brightness.dark, seed);

  static ThemeData _build(Brightness b, Color seed) {
    final dark = b == Brightness.dark;
    final ink = dark ? HColors.darkInk : HColors.ink;
    final ink2 = dark ? HColors.darkInk2 : HColors.ink2;
    final generated = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    final isBrand = seed.toARGB32() == HColors.primary.toARGB32();
    final bg = dark ? HColors.darkBackground : HColors.background;
    final surface = dark ? HColors.darkSurface : HColors.surface;
    final primary = dark
        ? (isBrand ? HColors.darkPrimary : generated.primary)
        : seed;
    final container = dark
        ? Color.alphaBlend(primary.withValues(alpha: .18), HColors.darkSurface)
        : (isBrand
              ? HColors.primarySoft
              : Color.alphaBlend(seed.withValues(alpha: .14), Colors.white));
    final scheme = generated.copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF00201D) : Colors.white,
      primaryContainer: container,
      onPrimaryContainer: dark ? HColors.darkInk : HColors.slate,
      secondary: dark ? const Color(0xFF8FB4BC) : HColors.slate,
      onSecondary: dark ? HColors.slateDeep : Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: ink2,
      surfaceContainerLowest: dark ? HColors.darkSurface : Colors.white,
      surfaceContainerLow: dark ? HColors.darkSurfaceAlt : HColors.surfaceAlt,
      surfaceContainer: dark
          ? const Color(0xFF223D48)
          : const Color(0xFFE4EFED),
      surfaceContainerHigh: dark
          ? const Color(0xFF284652)
          : const Color(0xFFDCE9E7),
      surfaceContainerHighest: dark
          ? const Color(0xFF2E4E5B)
          : const Color(0xFFD3E3E0),
      error: HColors.error,
      outline: dark ? const Color(0x33FFFFFF) : HColors.outlineStrong,
      outlineVariant: dark ? const Color(0x1FFFFFFF) : HColors.outline,
      inverseSurface: dark ? HColors.darkInk : HColors.slate,
      onInverseSurface: dark ? HColors.slate : Colors.white,
    );
'''+s[end:]
s=s.replace("fillColor: generated.surfaceContainerLowest,","fillColor: dark ? HColors.darkSurface : Colors.white,")
s=s.replace("        backgroundColor: HColors.ink,\n        contentTextStyle","        backgroundColor: HColors.slate,\n        contentTextStyle")
s=s.replace("""          minimumSize: const Size(0, 46),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.md)),
        ),
      ),
      outlinedButtonTheme""","""          minimumSize: const Size(0, 50),
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.md)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.lg)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: ink2,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelMedium,
      ),
      outlinedButtonTheme""")
s=s.replace("""          minimumSize: const Size(0, 46),
          foregroundColor: ink,""","""          minimumSize: const Size(0, 50),
          foregroundColor: ink,""")
s=s.replace("""      chipTheme: ChipThemeData(
        selectedColor: scheme.primaryContainer,""","""      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: scheme.primaryContainer,""")
s=s.replace("""        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.pill)),""","""        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: HRadius.all(HRadius.pill)),""")
s=s.replace("""          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: ink2,""","""          backgroundColor: dark ? HColors.darkSurfaceAlt : Colors.white,
          foregroundColor: ink,""")
p.write_text(s)

sub('lib/core/widgets/surfaces.dart',"""      shape: RoundedRectangleBorder(borderRadius: br, side: BorderSide.none),""","""      shape: RoundedRectangleBorder(
        borderRadius: br,
        side: color == null
            ? BorderSide(color: t.colorScheme.outlineVariant)
            : BorderSide.none,
      ),""")
sub('lib/core/widgets/surfaces.dart',"""                  color: Color(0x07452C69),
                  blurRadius: 22,
                  offset: Offset(0, 7),""","""                  color: Color(0x0A1A3440),
                  blurRadius: 14,
                  offset: Offset(0, 4),""")
sub('lib/core/widgets/surfaces.dart',"""    builder: (_, v, c) =>
        Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c),""","""    builder: (_, v, c) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c),
    ),""")
sub('lib/core/widgets/common.dart',"""        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [adaptiveAccent(context, color).withValues(alpha: .10), adaptiveAccent(context, color).withValues(alpha: .20)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),""","""        color: adaptiveAccent(context, color).withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .18 : .11,
        ),
        borderRadius: BorderRadius.circular(size * 0.30),""")
sub('lib/core/widgets/common.dart',"""              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: t.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(HRadius.lg),
              ),
              child: Icon(icon, size: 34, color: t.colorScheme.primary),""","""              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: t.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: t.colorScheme.primary),""")
sub('lib/core/widgets/common.dart',"""          Expanded(child: Text(title, style: t.textTheme.titleMedium)),""","""          Expanded(
            child: Text(
              title,
              style: t.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -.2,
              ),
            ),
          ),""")
print('theme patch ok')
