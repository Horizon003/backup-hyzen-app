import 'package:flutter/material.dart';

import 'office_ui.dart';

/// Large scanned-page preview. In crop mode it shows the blue frame with four
/// round corner handles and four pill edge handles from the approved design.
class ScanReviewCanvas extends StatelessWidget {
  const ScanReviewCanvas({
    super.key,
    required this.path,
    required this.crop,
    required this.rect,
    required this.onRect,
  });
  final String path;
  final bool crop;
  final Rect rect;
  final ValueChanged<Rect> onRect;

  void _drag(int i, Offset d, Size size) {
    final dx = d.dx / size.width, dy = d.dy / size.height;
    var l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    const min = .12;
    if (i == 0 || i == 6 || i == 7) l = (l + dx).clamp(0, r - min);
    if (i == 2 || i == 3 || i == 4) r = (r + dx).clamp(l + min, 1);
    if (i == 0 || i == 1 || i == 2) t = (t + dy).clamp(0, b - min);
    if (i == 4 || i == 5 || i == 6) b = (b + dy).clamp(t + min, 1);
    onRect(Rect.fromLTRB(l, t, r, b));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PageImageData?>(
    future: OfficeImageCache.image(path),
    builder: (context, snap) {
      final data = snap.data;
      if (data == null) {
        return Center(
          child: snap.connectionState == ConnectionState.done
              ? Icon(
                  Icons.broken_image_outlined,
                  color: OfficeColors.muted(context),
                  size: 48,
                )
              // Static placeholder: no endless spinner while bytes load.
              : Icon(
                  Icons.image_outlined,
                  color: OfficeColors.muted(context),
                  size: 48,
                ),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: data.ratio,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = box.biggest;
              Offset at(double x, double y) =>
                  Offset(x * size.width, y * size.height);
              final points = [
                at(rect.left, rect.top),
                at(rect.center.dx, rect.top),
                at(rect.right, rect.top),
                at(rect.right, rect.center.dy),
                at(rect.right, rect.bottom),
                at(rect.center.dx, rect.bottom),
                at(rect.left, rect.bottom),
                at(rect.left, rect.center.dy),
              ];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.memory(
                          data.bytes,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          cacheWidth:
                              (size.width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round()
                                  .clamp(200, 1600),
                        ),
                      ),
                    ),
                  ),
                  if (crop) ...[
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _CropFrame(rect)),
                      ),
                    ),
                    for (var i = 0; i < 8; i++)
                      Positioned(
                        left: points[i].dx - 22,
                        top: points[i].dy - 22,
                        child: Semantics(
                          label: i.isEven
                              ? 'Corner crop handle ${i ~/ 2 + 1}'
                              : 'Edge crop handle',
                          child: GestureDetector(
                            key: ValueKey('crop-handle-$i'),
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (d) => _drag(i, d.delta, size),
                            child: SizedBox.square(
                              dimension: 44,
                              child: Center(
                                child: _Handle(
                                  corner: i.isEven,
                                  vertical: i == 3 || i == 7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _Handle extends StatelessWidget {
  const _Handle({required this.corner, required this.vertical});
  final bool corner, vertical;
  @override
  Widget build(BuildContext context) => Container(
    width: corner ? 22 : (vertical ? 13 : 30),
    height: corner ? 22 : (vertical ? 30 : 13),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: corner ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: corner ? null : BorderRadius.circular(3),
      border: Border.all(color: OfficeColors.blue, width: 2.4),
    ),
  );
}

class _CropFrame extends CustomPainter {
  _CropFrame(this.rect);
  final Rect rect;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(r),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRect(
      r,
      Paint()
        ..color = OfficeColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _CropFrame old) => old.rect != rect;
}

/// Numbered thumbnail strip (long-press and drag to reorder).
class ScanThumbStrip extends StatelessWidget {
  const ScanThumbStrip({
    super.key,
    required this.pages,
    required this.selected,
    required this.onSelect,
    required this.onReorder,
    required this.onOptions,
  });
  final List<String> pages;
  final int selected;
  final ValueChanged<int> onSelect, onOptions;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 132,
    child: ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
      itemCount: pages.length,
      onReorder: (from, to) => onReorder(from, to > from ? to - 1 : to),
      proxyDecorator: (child, _, __) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
        key: ValueKey(pages[i]),
        index: i,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Semantics(
            button: true,
            selected: i == selected,
            label: 'Page ${i + 1}',
            child: GestureDetector(
              onTap: () => onSelect(i),
              onDoubleTap: () => onOptions(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 116,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: OfficeColors.dark(context)
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE6E8EC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: i == selected
                        ? OfficeColors.blue
                        : Colors.transparent,
                    width: 2.4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: OfficeFileThumbnail(
                          path: pages[i],
                          version: pages[i],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC5A5A5E),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Small rounded pill like "Straighten" / "Page 1 of 4".
class ScanPill extends StatelessWidget {
  const ScanPill({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.onTap,
  });
  final String label;
  final IconData? icon, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final ink = OfficeColors.ink(context);
    return Material(
      color: OfficeColors.dark(context)
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFE6E8EC),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: OfficeColors.blue, size: 24),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: ink, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ScanRoundButton extends StatelessWidget {
  const ScanRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: OfficeColors.dark(context) ? const Color(0xFF2C2C2E) : Colors.white,
    shape: const CircleBorder(),
    elevation: 1,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null
            ? OfficeColors.muted(context)
            : OfficeColors.ink(context),
      ),
    ),
  );
}
