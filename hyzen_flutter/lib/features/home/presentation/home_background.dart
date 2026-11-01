import 'package:flutter/material.dart';

class HomeAtmosphere extends StatelessWidget {
  const HomeAtmosphere({super.key, required this.child, this.content = false});
  final Widget child;
  final bool content;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF101012) : const Color(0xFFF1F1F3);
    if (content) return ColoredBox(color: base, child: child);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final sky = MediaQuery.paddingOf(context).top + 72 +
        (scale > 1.5 ? 370 * scale.clamp(1, 2) : 230);
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: base)),
      Positioned(top: 0, left: 0, right: 0, height: sky, child: const ColoredBox(color: Colors.black)),
      child,
    ]);
  }
}
