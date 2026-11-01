import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Opaque surfaces; deliberately inexpensive to compose on Android.
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.radius = HRadius.lg,
    this.padding,
    this.blur = 0,
    this.borderRadius,
    this.tint,
  });
  final Widget child;
  final double radius, blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? tint;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: tint?.withAlpha(255) ?? Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
    ),
    child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
  );
}

class HCard extends StatelessWidget {
  const HCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.radius = HRadius.md,
    this.color,
    this.shadow = true,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool shadow;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final br = BorderRadius.circular(radius);
    final card = Material(
      color: color ?? t.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: br,
        side: color == null
            ? BorderSide(color: t.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow && t.brightness == Brightness.light
            ? const [
                BoxShadow(
                  color: Color(0x0A1A3440),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: card,
    );
    return semanticLabel == null
        ? decorated
        : Semantics(
            button: onTap != null,
            label: semanticLabel,
            child: decorated,
          );
  }
}

class HBackground extends StatelessWidget {
  const HBackground({super.key, required this.child, this.intense = false});
  final Widget child;
  final bool intense;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
}

/// One entrance animation; no continuous blur, glow or moving background.
class HEntrance extends StatelessWidget {
  const HEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(
      begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0,
      end: 1,
    ),
    duration: HMotion.slow,
    curve: HMotion.curve,
    child: child,
    builder: (_, v, c) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c),
    ),
  );
}
