import 'package:flutter/material.dart';
class HomeAtmosphere extends StatelessWidget {
  const HomeAtmosphere({super.key, required this.child, this.content = false});
  final Widget child;
  final bool content;
  @override
  Widget build(BuildContext context) => ColoredBox(color: content ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF101012) : const Color(0xFFF1F1F3)) : Colors.black, child: child);
}
