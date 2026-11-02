import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/media_upload.dart';
import '../../viewer/document_bytes.dart';
import '../../viewer/document_flow.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_pdf_engine.dart';
import 'office_file_actions.dart';
import 'office_ui.dart';
import 'scan_review_canvas.dart';
import 'studio_annotation_screen.dart';

Future<void> showCreatePdf(BuildContext context) async {
  final router = GoRouter.of(context);
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create PDF', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Scan with camera'),
              subtitle: const Text('Capture and add pages'),
              onTap: () => Navigator.pop(c, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('From gallery images'),
              subtitle: const Text('Select photos, arrange and save'),
              onTap: () => Navigator.pop(c, 'gallery'),
            ),
          ],
        ),
      ),
    ),
  );
  if (source != null) router.push('/create-pdf?source=$source');
}

class ScanPdfScreen extends ConsumerStatefulWidget {
  const ScanPdfScreen({super.key, this.initialAction});
  final String? initialAction;
  @override
  ConsumerState<ScanPdfScreen> createState() => _ScanPdfScreenState();
}

class _ScanPdfScreenState extends ConsumerState<ScanPdfScreen>
    with WidgetsBindingObserver {
  static const _camera = MethodChannel('com.hyzen.pharmd/camera_pages');
  final _name = TextEditingController(
    text: 'Office Workspace ${officeDate(DateTime.now())}',
  );
  static const _full = Rect.fromLTRB(0, 0, 1, 1);
  bool _crop = false;
  Rect _cropRect = _full;
  List<String> _pages = [];
  int _selectedPage = 0;
  bool _busy = true;
  String? _error;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    try {
      if (_android) {
        _pages = await _camera.invokeListMethod<String>('recover') ?? [];
      }
    } catch (_) {
      /* The draft is optional on unsupported platforms. */
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.initialAction == 'camera') {
      await _scan();
    } else if (widget.initialAction == 'gallery') {
      await _gallery();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy && _android) {
      _refreshDraft();
    }
  }

  Future<void> _refreshDraft() async {
    try {
      final pages = await _camera.invokeListMethod<String>('recover');
      if (mounted && !_busy && pages != null) {
        setState(() {
          _pages = pages;
          _selectedPage = pages.isEmpty
              ? 0
              : _selectedPage.clamp(0, pages.length - 1);
        });
      }
    } catch (_) {}
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PlatformException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              e.message ?? 'Could not prepare this page. Please retry.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not finish. Your pages are still here; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() => _work(() async {
    try {
      final paths = await const MethodChannel(
        'com.hyzen.pharmd/document_scanner',
      ).invokeListMethod<String>('scan');
      if (mounted && paths != null) {
        setState(() {
          _pages = paths;
          _selectedPage = 0;
        });
      }
    } on MissingPluginException {
      // Older/unsupported platforms keep the explicit basic-camera fallback.
      final paths = await _camera.invokeListMethod<String>('capture');
      if (mounted && paths != null) {
        setState(() {
          _pages = paths;
          _selectedPage = 0;
        });
      }
    }
  });

  void _back() {
    if (_busy) return;
    // Draft is durable. Leaving the editor never closes the app or discards it.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pdf-studio');
    }
  }

  Future<void> _capture() => _work(() async {
    final paths = await _camera.invokeListMethod<String>('capture');
    if (mounted && paths != null) setState(() => _pages = paths);
  });
  Future<void> _gallery() => _work(() async {
    final files = await StudioPdfEngine.pickFiles();
    final paths = files
        .where(
          (f) => RegExp(
            r'\.(jpe?g|png|webp)$',
            caseSensitive: false,
          ).hasMatch(f.path),
        )
        .map((f) => f.path)
        .toList();
    if (files.isNotEmpty && paths.isEmpty) {
      throw PlatformException(
        code: 'images',
        message: 'Choose JPG, PNG or WebP images.',
      );
    }
    if (paths.isEmpty) return;
    final next = _android
        ? await _camera.invokeListMethod<String>('addImages', {'paths': paths})
        : [..._pages, ...paths];
    if (mounted && next != null) {
      setState(() {
        _pages = next;
        _selectedPage = next.isEmpty
            ? 0
            : _selectedPage.clamp(0, next.length - 1);
      });
    }
  });
  Future<void> _replace(List<String> pages) => _work(() async {
    final next = _android
        ? await _camera.invokeListMethod<String>('replace', {'paths': pages})
        : pages;
    if (mounted && next != null) {
      setState(() {
        _pages = next;
        _selectedPage = next.isEmpty
            ? 0
            : _selectedPage.clamp(0, next.length - 1);
      });
    }
  });
  Future<void> _rotate(String path) => _work(() async {
    final next = await _camera.invokeListMethod<String>('rotate', {
      'path': path,
    });
    if (mounted && next != null) {
      setState(() {
        _pages = next;
        _selectedPage = next.isEmpty
            ? 0
            : _selectedPage.clamp(0, next.length - 1);
      });
    }
  });
  Future<void> _save({bool edit = false}) => _work(() async {
    if (_pages.isEmpty) return;
    final path = await StudioPdfEngine.imagesToPdf(_pages);
    final count = await StudioPdfEngine.pageCount(path);
    if (count != _pages.length) throw const FormatException('Incomplete PDF');
    final name = _cleanFileName(
      _name.text,
    ).replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
    final item = await ref
        .read(pdfStudioHistoryProvider.notifier)
        .importFile(
          path,
          originalFileName: '${name.isEmpty ? 'Scanned notes' : name}.pdf',
          sourceType: 'IMAGE_SCAN',
          operationBadge: 'SCANNED',
        );
    await ref
        .read(pdfStudioHistoryProvider.notifier)
        .updatePageCount(item.id, count);
    if (_android) await _camera.invokeMethod<bool>('clear');
    if (edit) {
      if (!mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      context.replace('/pdf-studio/viewer/${item.id}');
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => StudioAnnotationScreen(file: item),
        ),
      );
      return;
    }
    if (mounted) {
      final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * .72,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                  title: Text('Saved ${item.displayName}'),
                  subtitle: Text(
                    '$count page${count == 1 ? '' : 's'} · Office Workspace',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Open PDF'),
                  onTap: () => Navigator.pop(sheet, 'open'),
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: const Text('Share PDF'),
                  onTap: () => Navigator.pop(sheet, 'share'),
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded),
                  title: const Text('Save a copy to device'),
                  onTap: () => Navigator.pop(sheet, 'locate'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted) return;
      if (action == 'share') {
        await MediaUpload.shareDocument(
          item.internalFilePath,
          item.displayName,
          'application/pdf',
        );
      } else if (action == 'locate') {
        await MediaUpload.exportDocument(
          item.internalFilePath,
          item.displayName,
          'application/pdf',
        );
      }
      if (mounted) context.replace('/pdf-studio/viewer/${item.id}');
    }
  });

  String _cleanFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\.+$'), '');
    return cleaned.isEmpty ? 'Scanned notes' : cleaned;
  }

  int get _sel =>
      _pages.isEmpty ? 0 : _selectedPage.clamp(0, _pages.length - 1);

  void _setPages(List<String> next) => setState(() {
    _pages = next;
    _selectedPage = next.isEmpty ? 0 : _selectedPage.clamp(0, next.length - 1);
  });

  Future<void> _rename() async {
    final v = await askOfficeText(
      context,
      title: 'PDF name',
      initial: _name.text,
      label: 'Name',
    );
    if (v != null && v.trim().isNotEmpty && mounted) {
      setState(() => _name.text = v.trim());
    }
  }

  /// Replaces the selected page with a fresh capture at the same position.
  Future<void> _retake() async {
    if (_busy || _pages.isEmpty) return;
    final index = _sel;
    final before = [..._pages];
    await _scan();
    if (!mounted) return;
    final added = _pages.where((p) => !before.contains(p)).toList();
    if (added.isEmpty) {
      setState(() => _selectedPage = index);
      return;
    }
    final next = [...before];
    next[index] = added.first;
    next.addAll(added.skip(1));
    await _replace(next);
    if (mounted) setState(() => _selectedPage = index);
  }

  Future<void> _applyCrop() async {
    final rect = _cropRect;
    if (_pages.isEmpty || rect == _full) return;
    final path = _pages[_sel];
    await _work(() async {
      final next = await _camera.invokeListMethod<String>('edit', {
        'paths': [path],
        'filter': 'original',
        'crop': [rect.left, rect.top, rect.right, rect.bottom],
      });
      if (mounted && next != null) _setPages(next);
    });
    if (mounted) setState(() => _cropRect = _full);
  }

  Future<void> _toggleCrop() async {
    if (_crop) {
      await _applyCrop();
      if (mounted) setState(() => _crop = false);
    } else {
      setState(() {
        _crop = true;
        _cropRect = _full;
      });
    }
  }

  /// Auto-detects the paper edges and perspective-corrects the page.
  Future<void> _straighten() async {
    if (_pages.isEmpty) return;
    final path = _pages[_sel];
    await _work(() async {
      final info = await _camera.invokeMapMethod<String, dynamic>('pageInfo', {
        'path': path,
      });
      final original = info?['original'] is String
          ? info!['original'] as String
          : path;
      final quad = await _camera.invokeListMethod<double>('detect', {
        'path': original,
      });
      if (quad == null || quad.length != 8) {
        throw PlatformException(
          code: 'edges',
          message: 'Page edges were not found. Drag the crop handles instead.',
        );
      }
      final next = await _camera.invokeListMethod<String>('adjust', {
        'paths': [path],
        'quad': quad,
      });
      if (mounted && next != null) _setPages(next);
    });
    if (mounted) {
      setState(() {
        _crop = false;
        _cropRect = _full;
      });
    }
  }

  Future<void> _filters() async {
    if (_pages.isEmpty || _busy) return;
    var all = false;
    final choice = await showOfficeSheet<String>(
      context,
      (sheet) => StatefulBuilder(
        builder: (c, set) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            for (final f in const [
              ('original', 'Original', Icons.image_outlined),
              ('magic', 'Magic colour', Icons.auto_fix_high_rounded),
              ('gray', 'Grayscale', Icons.filter_b_and_w_rounded),
              ('bw', 'Black & white', Icons.contrast_rounded),
            ])
              OfficeSheetItem(
                icon: f.$3,
                label: f.$2,
                onTap: () => Navigator.pop(sheet, f.$1),
              ),
            if (_pages.length > 1)
              SwitchListTile(
                value: all,
                activeTrackColor: OfficeColors.blue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Apply to all pages',
                  style: TextStyle(color: OfficeColors.ink(c)),
                ),
                onChanged: (v) => set(() => all = v),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final paths = all ? [..._pages] : [_pages[_sel]];
    await _work(() async {
      final next = await _camera.invokeListMethod<String>('adjust', {
        'paths': paths,
        'filter': choice,
      });
      if (mounted && next != null) _setPages(next);
    });
  }

  Future<void> _adjust() async {
    if (_pages.isEmpty || _busy) return;
    final path = _pages[_sel];
    var brightness = 0.0, contrast = 0.0;
    try {
      final info = await _camera.invokeMapMethod<String, dynamic>('pageInfo', {
        'path': path,
      });
      brightness = ((info?['brightness'] as num?) ?? 0).toDouble();
      contrast = ((info?['contrast'] as num?) ?? 0).toDouble();
    } catch (_) {}
    if (!mounted) return;
    final ok = await showOfficeSheet<bool>(
      context,
      (sheet) => StatefulBuilder(
        builder: (c, set) {
          final label = TextStyle(
            color: OfficeColors.ink(c),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Brightness  ${brightness.round()}', style: label),
                Slider(
                  value: brightness,
                  min: -100,
                  max: 100,
                  divisions: 40,
                  activeColor: OfficeColors.blue,
                  onChanged: (v) => set(() => brightness = v),
                ),
                Text('Contrast  ${contrast.round()}', style: label),
                Slider(
                  value: contrast,
                  min: -100,
                  max: 100,
                  divisions: 40,
                  activeColor: OfficeColors.blue,
                  onChanged: (v) => set(() => contrast = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: officeOutlineStyle(c),
                        onPressed: () => set(() {
                          brightness = 0;
                          contrast = 0;
                        }),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: officePrimaryStyle(),
                        onPressed: () => Navigator.pop(sheet, true),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    await _work(() async {
      final next = await _camera.invokeListMethod<String>('adjust', {
        'paths': [path],
        'brightness': brightness.round(),
        'contrast': contrast.round(),
      });
      if (mounted && next != null) _setPages(next);
    });
  }

  Future<void> _pageOptions(int i) async {
    if (_busy || i >= _pages.length) return;
    final action = await showOfficeSheet<String>(
      context,
      (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          if (i > 0)
            OfficeSheetItem(
              icon: Icons.arrow_back_rounded,
              label: 'Move page earlier',
              onTap: () => Navigator.pop(sheet, 'left'),
            ),
          if (i + 1 < _pages.length)
            OfficeSheetItem(
              icon: Icons.arrow_forward_rounded,
              label: 'Move page later',
              onTap: () => Navigator.pop(sheet, 'right'),
            ),
          OfficeSheetItem(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate page',
            onTap: () => Navigator.pop(sheet, 'rotate'),
          ),
          OfficeSheetItem(
            icon: Icons.delete_outline_rounded,
            label: 'Delete page ${i + 1}',
            destructive: true,
            onTap: () => Navigator.pop(sheet, 'delete'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'left' || 'right':
        final to = action == 'left' ? i - 1 : i + 1;
        final next = [..._pages];
        next.insert(to, next.removeAt(i));
        await _replace(next);
        if (mounted) setState(() => _selectedPage = to);
      case 'rotate':
        await _rotate(_pages[i]);
      case 'delete':
        await _replace([..._pages]..removeAt(i));
    }
  }

  Future<void> _finish({bool edit = false}) async {
    if (_crop) {
      await _applyCrop();
      if (mounted) setState(() => _crop = false);
    }
    if (mounted) await _save(edit: edit);
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 64,
            color: OfficeColors.muted(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first page',
            style: TextStyle(
              color: OfficeColors.ink(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan a document or choose photos to make a PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(color: OfficeColors.muted(context)),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(documentDraftRevisionProvider, (_, __) {
      if (!_busy) _refreshDraft();
    });
    final count = _pages.length;
    final has = count > 0;
    final sel = _sel;
    final idle = !_busy && has;
    final tools = [
      (
        Icons.cameraswitch_outlined,
        'Retake',
        idle && _android ? _retake : null,
        false,
      ),
      (Icons.crop_rounded, 'Crop', idle ? _toggleCrop : null, _crop),
      (
        Icons.rotate_right_rounded,
        'Rotate',
        idle ? () => _rotate(_pages[sel]) : null,
        false,
      ),
      (
        Icons.edit_note_rounded,
        'Edit text',
        idle ? () => _finish(edit: true) : null,
        false,
      ),
      (Icons.blur_circular_rounded, 'Filters', idle ? _filters : null, false),
      (Icons.brightness_6_outlined, 'Adjust', idle ? _adjust : null, false),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: OfficeColors.canvas(context),
        body: Column(
          children: [
            const OfficeBrandHeader(),
            WorkspaceBar(
              title: _name.text,
              onEditTitle: _busy ? null : _rename,
              onHome: _back,
              onSmart: _busy ? null : _gallery,
              smartIcon: Icons.add_photo_alternate_outlined,
              smartTooltip: 'Choose gallery images',
            ),
            SizedBox(
              height: 2,
              child: _busy
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      color: OfficeColors.blue,
                    )
                  : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (_android)
                      TextButton.icon(
                        onPressed: _busy ? null : _capture,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Use basic camera'),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: !has
                  ? _emptyState(context)
                  : GestureDetector(
                      onHorizontalDragEnd: _crop
                          ? null
                          : (d) {
                              final v = d.primaryVelocity ?? 0;
                              if (v < -80 && sel + 1 < count) {
                                setState(() => _selectedPage = sel + 1);
                              } else if (v > 80 && sel > 0) {
                                setState(() => _selectedPage = sel - 1);
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 22, 30, 14),
                        child: ScanReviewCanvas(
                          key: ValueKey(_pages[sel]),
                          path: _pages[sel],
                          crop: _crop,
                          rect: _cropRect,
                          onRect: (r) => setState(() => _cropRect = r),
                        ),
                      ),
                    ),
            ),
            if (has && (_crop || count == 1))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ScanPill(
                  label: 'Straighten',
                  icon: Icons.grid_on_rounded,
                  onTap: _busy ? null : _straighten,
                ),
              ),
            if (has && !_crop && count > 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    ScanRoundButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Previous page',
                      onTap: sel > 0
                          ? () => setState(() => _selectedPage = sel - 1)
                          : null,
                    ),
                    const Spacer(),
                    ScanPill(
                      label: 'Page ${sel + 1} of $count',
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: () => _pageOptions(sel),
                    ),
                    const Spacer(),
                    ScanRoundButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Next page',
                      onTap: sel + 1 < count
                          ? () => setState(() => _selectedPage = sel + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              ScanThumbStrip(
                pages: _pages,
                selected: sel,
                onSelect: (i) => setState(() => _selectedPage = i),
                onOptions: _pageOptions,
                onReorder: (from, to) {
                  if (_busy || from == to) return;
                  final next = [..._pages];
                  next.insert(to, next.removeAt(from));
                  _replace(next);
                  setState(() => _selectedPage = to);
                },
              ),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                color: OfficeColors.bar(context),
                border: Border(
                  top: BorderSide(color: OfficeColors.divider(context)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          for (final t in tools)
                            Expanded(
                              child: OfficeToolButton(
                                icon: t.$1,
                                label: t.$2,
                                onTap: t.$3,
                                selected: t.$4,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('scan-more'),
                              style: officeOutlineStyle(context),
                              onPressed: _busy
                                  ? null
                                  : (_android ? _scan : _gallery),
                              child: FittedBox(
                                child: Text(
                                  has
                                      ? 'Keep scanning'
                                      : (_android ? 'Scan' : 'Add images'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              style: officePrimaryStyle(),
                              onPressed: _busy || !has ? null : _finish,
                              child: const Text('Save PDF'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanPageImage extends StatefulWidget {
  const ScanPageImage({super.key, required this.path});
  final String path;
  @override
  State<ScanPageImage> createState() => _ScanPageImageState();
}

class _ScanPageImageState extends State<ScanPageImage> {
  late final Future<Uint8List> _bytes = documentBytes(widget.path);
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (_, s) => s.hasData
        ? Image.memory(
            s.data!,
            cacheWidth: 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
          )
        : const Icon(Icons.image_outlined),
  );
}
