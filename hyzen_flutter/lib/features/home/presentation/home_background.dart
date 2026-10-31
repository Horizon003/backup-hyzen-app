import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Home-only cached decoration. Scroll and mascot frames do not repaint grain.
class HomeAtmosphere extends StatelessWidget {
  const HomeAtmosphere({super.key, required this.child, this.content = false});
  final Widget child;
  final bool content;
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _Atmosphere(Theme.of(context).brightness == Brightness.dark, content)))),
    child,
  ]);
}
class _Atmosphere extends CustomPainter {
  _Atmosphere(this.dark, this.content);
  final bool dark, content;
  static final dots = List<Offset>.generate(160, (i) { final random = math.Random(i * 71 + 4); return Offset(random.nextDouble(), random.nextDouble()); });
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = dark ? const Color(0xFF353538) : const Color(0xFFF6F6F4);
    if (content && !dark) {
      canvas.drawRect(rect, Paint()..color = base);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 96), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF202022), base]).createShader(Rect.fromLTWH(0, 0, size.width, 96)));
    } else {
      canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, const Color(0xFF202022), dark ? base : const Color(0xFF202022)]).createShader(rect));
    }
    final grain = Paint()..color = (dark || !content ? Colors.white : Colors.black).withValues(alpha: .025);
    for (final dot in dots) canvas.drawCircle(Offset(dot.dx * size.width, dot.dy * size.height), .65, grain);
  }
  @override
  bool shouldRepaint(covariant _Atmosphere old) => dark != old.dark || content != old.content;
}
