import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../viewer/document_bytes.dart';

class ScanPageEdit {
  const ScanPageEdit(this.filter, this.crop, this.all);
  final String filter;
  final List<double>? crop;
  final bool all;
}

class ScanPageEditor extends StatefulWidget {
  const ScanPageEditor({super.key, required this.path});
  final String path;
  @override
  State<ScanPageEditor> createState() => _ScanPageEditorState();
}

class _ScanPageEditorState extends State<ScanPageEditor> {
  late final _image = _load();
  String _filter = 'original';
  bool _crop = false, _all = false;
  Rect _rect = const Rect.fromLTRB(.03, .03, .97, .97);
  Future<({Uint8List bytes, double ratio})> _load() async {
    final bytes = await documentBytes(widget.path);
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
    final frame = await codec.getNextFrame();
    final ratio = frame.image.width / frame.image.height;
    frame.image.dispose(); codec.dispose();
    return (bytes: bytes, ratio: ratio);
  }
  List<double> get _matrix {
    if (_filter == 'gray' || _filter == 'bw') {
      final f = _filter == 'bw' ? 3.5 : 1.0, o = 128 * (1 - (_filter == 'bw' ? 3.5 : 1.0));
      return [.213*f,.715*f,.072*f,0,o,.213*f,.715*f,.072*f,0,o,.213*f,.715*f,.072*f,0,o,0,0,0,1,0];
    }
    final f = _filter == 'contrast' ? 1.35 : 1.0, o = 128 * (1 - f);
    return [f,0,0,0,o,0,f,0,0,o,0,0,f,0,o,0,0,0,1,0];
  }
  void _drag(int i, Offset delta, Size size) {
    final dx = delta.dx / size.width, dy = delta.dy / size.height;
    var l = _rect.left, t = _rect.top, r = _rect.right, b = _rect.bottom;
    if (i == 0 || i == 3) { l = (l + dx).clamp(0, r - .1); } else { r = (r + dx).clamp(l + .1, 1); }
    if (i < 2) { t = (t + dy).clamp(0, b - .1); } else { b = (b + dy).clamp(t + .1, 1); }
    setState(() => _rect = Rect.fromLTRB(l, t, r, b));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adjust page'), actions: [TextButton(
      onPressed: () => Navigator.pop(context, ScanPageEdit(_filter,
        _crop ? [_rect.left, _rect.top, _rect.right, _rect.bottom] : null, _all)), child: const Text('Apply'))]),
    body: Column(children: [
      Expanded(child: FutureBuilder(
        future: _image,
        builder: (_, s) {
          if (s.hasError) return const Center(child: Text('Could not open this page.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final data = s.data!;
          return Padding(padding: const EdgeInsets.all(24), child: Center(child: AspectRatio(
            aspectRatio: data.ratio,
            child: LayoutBuilder(builder: (c, box) => Stack(children: [
              Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(_matrix),
                child: Image.memory(data.bytes, cacheWidth: 1200, fit: BoxFit.fill))),
              if (_crop) ...[
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CropMask(_rect, Theme.of(c).colorScheme.primary)))),
                for (var i = 0; i < 4; i++) Positioned(
                  left: (i == 0 || i == 3 ? _rect.left : _rect.right) * box.maxWidth - 16,
                  top: (i < 2 ? _rect.top : _rect.bottom) * box.maxHeight - 16,
                  child: GestureDetector(onPanUpdate: (d) => _drag(i, d.delta, box.biggest),
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Theme.of(c).colorScheme.primary, border: Border.all(color: Colors.white, width: 3)))),
                ),
              ],
            ])),
          )));
        },
      )),
      SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [for (final f in [('original','Original'),('contrast','Colour'),('gray','Gray'),('bw','B & W')])
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)))])),
        Row(children: [
          const SizedBox(width: 16), FilterChip(label: const Text('Crop'), avatar: const Icon(Icons.crop_rounded, size: 18), selected: _crop, onSelected: (v) => setState(() => _crop = v)),
          const Spacer(), const Text('Filter all pages'), Switch(value: _all, onChanged: (v) => setState(() => _all = v)), const SizedBox(width: 12),
        ]),
      ])),
    ]),
  );
}

class _CropMask extends CustomPainter {
  _CropMask(this.rect, this.color);
  final Rect rect;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(rect.left*size.width, rect.top*size.height, rect.right*size.width, rect.bottom*size.height);
    final path = Path()..fillType = PathFillType.evenOdd..addRect(Offset.zero & size)..addRect(r);
    canvas.drawPath(path, Paint()..color = Colors.black45);
    canvas.drawRect(r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant _CropMask old) => old.rect != rect || old.color != color;
}
