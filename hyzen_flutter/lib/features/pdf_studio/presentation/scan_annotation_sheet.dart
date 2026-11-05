import 'package:flutter/material.dart';
import 'office_ui.dart';

/// Draft annotations stay with the page; naming is deferred until PDF export.
class ScanAnnotationScreen extends StatefulWidget {
  const ScanAnnotationScreen({super.key, required this.path});
  final String path;
  @override
  State<ScanAnnotationScreen> createState() => _ScanAnnotationScreenState();
}

class _ScanAnnotationScreenState extends State<ScanAnnotationScreen> {
  late final _image = OfficeImageCache.image(widget.path);
  final _marks = <Map<String, dynamic>>[];
  bool _highlight = false;
  void _point(Offset position, Size size, bool start) {
    final point = [
      (position.dx / size.width).clamp(0.0, 1.0),
      (position.dy / size.height).clamp(0.0, 1.0),
    ];
    setState(() {
      if (start)
        _marks.add({'highlight': _highlight, 'points': <List<double>>[]});
      if (_marks.isNotEmpty) (_marks.last['points'] as List).add(point);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OfficeColors.canvas(context),
    appBar: AppBar(
      title: const Text('Annotate page'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _marks),
          child: const Text('Apply'),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: FutureBuilder<PageImageData?>(
            future: _image,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null)
                return const Center(child: Text('Loading page…'));
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: data.ratio,
                    child: LayoutBuilder(
                      builder: (context, box) => GestureDetector(
                        onPanStart: (d) =>
                            _point(d.localPosition, box.biggest, true),
                        onPanUpdate: (d) =>
                            _point(d.localPosition, box.biggest, false),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(data.bytes, fit: BoxFit.fill),
                            CustomPaint(painter: _MarksPainter(_marks)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Pen'),
                  selected: !_highlight,
                  onSelected: (_) => setState(() => _highlight = false),
                ),
                ChoiceChip(
                  label: const Text('Highlight'),
                  selected: _highlight,
                  onSelected: (_) => setState(() => _highlight = true),
                ),
                IconButton(
                  tooltip: 'Undo mark',
                  onPressed: _marks.isEmpty
                      ? null
                      : () => setState(() => _marks.removeLast()),
                  icon: const Icon(Icons.undo_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks);
  final List<Map<String, dynamic>> marks;
  @override
  void paint(Canvas canvas, Size size) {
    for (final mark in marks) {
      final points = mark['points'] as List;
      if (points.isEmpty) continue;
      final highlight = mark['highlight'] == true;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final p = points[i] as List;
        final x = (p[0] as num).toDouble() * size.width,
            y = (p[1] as num).toDouble() * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = highlight
              ? const Color(0x66FFC107)
              : const Color(0xFF182A61)
          ..strokeWidth = size.width * (highlight ? .035 : .005)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarksPainter oldDelegate) => true;
}
