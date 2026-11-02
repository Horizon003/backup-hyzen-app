import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/brand.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../notifications/notifications_screen.dart';
import '../../shell/app_shell.dart' show showAccountMenu;
import '../../viewer/document_bytes.dart';
import '../data/studio_pdf_engine.dart';

/// Office Workspace visual language (owner-approved mockups): calm neutral
/// canvas, one confident blue for actions and a deep navy floating action.
class OfficeColors {
  OfficeColors._();
  static const blue = Color(0xFF1473E6);
  static const navy = Color(0xFF0B3A8F);
  static bool dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color canvas(BuildContext c) =>
      dark(c) ? const Color(0xFF1B1B1D) : const Color(0xFFEEF0F3);
  static Color page(BuildContext c) => dark(c) ? Colors.black : Colors.white;
  static Color bar(BuildContext c) => dark(c) ? Colors.black : Colors.white;
  static Color sheet(BuildContext c) =>
      dark(c) ? const Color(0xFF1C1C1E) : Colors.white;
  static Color raised(BuildContext c) =>
      dark(c) ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F4);
  static Color ink(BuildContext c) =>
      dark(c) ? Colors.white : const Color(0xFF1C1C1E);
  static Color muted(BuildContext c) =>
      dark(c) ? const Color(0xFF9A9AA0) : const Color(0xFF6E6E73);
  static Color divider(BuildContext c) =>
      dark(c) ? const Color(0xFF2C2C2E) : const Color(0xFFE3E3E8);
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String officeDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String officeRelativeDate(DateTime d) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return officeDate(d);
}

/// Brand row: panda mark, wordmark, notification bell and profile avatar.
class OfficeBrandHeader extends ConsumerWidget {
  const OfficeBrandHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    return ColoredBox(
      color: OfficeColors.bar(context),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    Brand.logoAsset,
                    width: 36,
                    height: 36,
                    cacheWidth: 108,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PHARM D WITH HYZEN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OfficeColors.ink(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                      letterSpacing: -.1,
                    ),
                  ),
                ),
                // Account widgets need Firebase; previews/tests run without it.
                if (ready) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: OfficeColors.raised(context),
                      shape: BoxShape.circle,
                    ),
                    child: const NotificationBell(),
                  ),
                  const SizedBox(width: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final p = ref.watch(profileProvider).valueOrNull;
                      return Semantics(
                        button: true,
                        label: 'Profile & settings',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => showAccountMenu(context),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: OfficeColors.divider(context),
                                width: 1.5,
                              ),
                            ),
                            child: ProfileAvatar(
                              photoUrl: p?.photoUrl,
                              radius: 19,
                              fallback: p?.firstName ?? 'H',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home · editable dashed title · smart-tools row under the brand header.
class WorkspaceBar extends StatelessWidget {
  const WorkspaceBar({
    super.key,
    required this.title,
    this.onEditTitle,
    this.onHome,
    this.onSmart,
    this.smartTooltip = 'Smart tools',
  });
  final String title;
  final VoidCallback? onEditTitle, onHome, onSmart;
  final String smartTooltip;

  @override
  Widget build(BuildContext context) {
    final ink = OfficeColors.ink(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OfficeColors.bar(context),
        border: Border(
          top: BorderSide(color: OfficeColors.divider(context)),
          bottom: BorderSide(color: OfficeColors.divider(context)),
        ),
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Home',
              onPressed: onHome,
              icon: Icon(Icons.home_rounded, color: ink, size: 27),
            ),
            Expanded(
              child: Semantics(
                button: onEditTitle != null,
                label: 'Rename $title',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onEditTitle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: CustomPaint(
                            painter: _DashedUnderline(
                              ink.withValues(alpha: .7),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (onEditTitle != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.edit_rounded, size: 21, color: ink),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: smartTooltip,
              onPressed: onSmart,
              icon: SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 2,
                      child: Icon(Icons.article_outlined, color: ink, size: 25),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(Icons.auto_awesome, color: ink, size: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _DashedUnderline extends CustomPainter {
  _DashedUnderline(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    final y = size.height - 1;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 5).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedUnderline old) => old.color != color;
}

/// Bottom editing toolbar item (Retake / Crop / Rotate / Edit text / …).
class OfficeToolButton extends StatelessWidget {
  const OfficeToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : onTap == null
        ? OfficeColors.muted(context)
        : OfficeColors.ink(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? OfficeColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle officePrimaryStyle() => FilledButton.styleFrom(
  backgroundColor: OfficeColors.blue,
  foregroundColor: Colors.white,
  disabledBackgroundColor: OfficeColors.blue.withValues(alpha: .35),
  disabledForegroundColor: Colors.white70,
  minimumSize: const Size.fromHeight(54),
  shape: const StadiumBorder(),
  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
);

ButtonStyle officeOutlineStyle(BuildContext context) =>
    OutlinedButton.styleFrom(
      foregroundColor: OfficeColors.ink(context),
      minimumSize: const Size.fromHeight(54),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: OfficeColors.ink(context).withValues(alpha: .55),
        width: 1.4,
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );

/// Encoded image bytes plus aspect ratio, read without a full decode.
class PageImageData {
  const PageImageData(this.bytes, this.ratio);
  final Uint8List bytes;
  final double ratio;
}

/// Small LRU caches so scrolling lists and page switches never re-read or
/// re-render the same file (main source of jank on mid-range phones).
class OfficeImageCache {
  OfficeImageCache._();
  // Map literals are insertion-ordered (LinkedHashMap), which the LRU needs.
  static final _pages = <String, Future<PageImageData?>>{};
  static final _pdf = <String, Future<Uint8List?>>{};

  static Future<T> _lru<T>(
    Map<String, Future<T>> map,
    String key,
    int max,
    Future<T> Function() load,
  ) {
    final hit = map.remove(key);
    if (hit != null) return map[key] = hit;
    final future = load();
    map[key] = future;
    while (map.length > max) {
      map.remove(map.keys.first);
    }
    return future;
  }

  static Future<PageImageData?> image(String path) =>
      _lru(_pages, path, 16, () async {
        try {
          final bytes = await documentBytes(path);
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          final descriptor = await ui.ImageDescriptor.encoded(buffer);
          final ratio = descriptor.height == 0
              ? .75
              : descriptor.width / descriptor.height;
          descriptor.dispose();
          buffer.dispose();
          return PageImageData(bytes, ratio);
        } catch (_) {
          return null;
        }
      });

  static Future<Uint8List?> pdfFirstPage(String path, String version) =>
      _lru(_pdf, '$path#$version', 24, () async {
        try {
          return (await StudioPdfEngine.renderPage(path, 0)).bytes;
        } catch (_) {
          return null;
        }
      });

  static void forget(String path) {
    _pages.remove(path);
    _pdf.removeWhere((k, _) => k.startsWith('$path#'));
  }
}

/// Paper-style first-page preview of a workspace document.
class OfficeFileThumbnail extends StatefulWidget {
  const OfficeFileThumbnail({
    super.key,
    required this.path,
    required this.version,
    this.fallbackIcon = Icons.description_outlined,
    this.alignment = Alignment.topCenter,
  });
  final String path, version;
  final IconData fallbackIcon;
  final Alignment alignment;

  @override
  State<OfficeFileThumbnail> createState() => _OfficeFileThumbnailState();
}

class _OfficeFileThumbnailState extends State<OfficeFileThumbnail> {
  late Future<Uint8List?> _bytes = _load();

  Future<Uint8List?> _load() {
    final lower = widget.path.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return OfficeImageCache.pdfFirstPage(widget.path, widget.version);
    }
    if (RegExp(r'\.(jpe?g|png|webp)$').hasMatch(lower)) {
      return OfficeImageCache.image(widget.path).then((d) => d?.bytes);
    }
    return Future.value(null);
  }

  @override
  void didUpdateWidget(covariant OfficeFileThumbnail old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.version != widget.version) {
      _bytes = _load();
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LayoutBuilder(
          builder: (context, box) => FutureBuilder<Uint8List?>(
            future: _bytes,
            builder: (context, snap) {
              final data = snap.data;
              if (data == null) {
                return Center(
                  child: Icon(
                    widget.fallbackIcon,
                    size: (box.maxWidth * .32).clamp(18, 48),
                    color: const Color(0xFF9A9AA0),
                  ),
                );
              }
              return Image.memory(
                data,
                fit: BoxFit.cover,
                alignment: widget.alignment,
                gaplessPlayback: true,
                cacheWidth:
                    (box.maxWidth * MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(48, 720),
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Rounded bottom sheet chrome shared by the Office sheets.
Future<T?> showOfficeSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: OfficeColors.sheet(context),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheet) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .86,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: OfficeColors.muted(sheet).withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: builder(sheet)),
            ],
          ),
        ),
      ),
    );

/// One row of an Office action sheet.
class OfficeSheetItem extends StatelessWidget {
  const OfficeSheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFE5484D)
        : OfficeColors.ink(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 25, color: color),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfficeSheetDivider extends StatelessWidget {
  const OfficeSheetDivider({super.key});
  @override
  Widget build(BuildContext context) => Divider(
    height: 14,
    thickness: 1,
    indent: 38,
    endIndent: 32,
    color: OfficeColors.divider(context),
  );
}
