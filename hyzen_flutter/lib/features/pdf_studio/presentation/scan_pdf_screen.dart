import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/common.dart';
import '../../../core/utils/media_upload.dart';
import '../../viewer/document_bytes.dart';
import '../../viewer/document_flow.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_pdf_engine.dart';
import 'scan_page_editor.dart';
import 'page_grid.dart';
import 'scan_review_panel.dart';

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
  final _name = TextEditingController(text: 'Scanned notes');
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

  Future<void> _editPage(int i) async {
    if (_busy) return;
    final edit = await Navigator.of(context).push<ScanPageEdit>(
      MaterialPageRoute(builder: (_) => ScanPageEditor(path: _pages[i])),
    );
    if (edit == null || !mounted) return;
    await _work(() async {
      var next = [..._pages];
      if (edit.crop != null) {
        next =
            await _camera.invokeListMethod<String>('edit', {
              'paths': [next[i]],
              'filter': 'original',
              'crop': edit.crop,
            }) ??
            next;
        if (mounted) setState(() => _pages = next);
      }
      if (edit.filter != 'original') {
        next =
            await _camera.invokeListMethod<String>('edit', {
              'paths': edit.all ? next : [next[i]],
              'filter': edit.filter,
            }) ??
            next;
      }
      if (mounted) setState(() => _pages = next);
    });
  }

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
  Future<void> _save() => _work(() async {
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

  @override
  Widget build(BuildContext context) {
    ref.listen(documentDraftRevisionProvider, (_, __) {
      if (!_busy) _refreshDraft();
    });
    final t = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: HTopBar(
          title: 'Create PDF',
          subtitle: '${_pages.length} pages',
          onBack: _back,
        ),
        body: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: t.colorScheme.error),
                ),
              ),
            if (_error != null && _android)
              TextButton.icon(
                onPressed: _busy ? null : _capture,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Use basic camera'),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'PDF name',
                  isDense: true,
                  counterText: '',
                ),
              ),
            ),
            Expanded(
              child: _pages.isEmpty
                  ? const EmptyState(
                      icon: Icons.document_scanner_outlined,
                      title: 'Add your first page',
                      message: 'Scan a document or choose photos below.',
                    )
                  : Column(
                      children: [
                        ScanReviewPanel(
                          pages: _pages,
                          selected: _selectedPage.clamp(0, _pages.length - 1),
                          onSelected: (index) =>
                              setState(() => _selectedPage = index),
                        ),
                        Expanded(
                          child: PageGrid(
                            count: _pages.length,
                            identity: (i) => _pages[i],
                            image: (i) => ScanPageImage(
                              key: ValueKey(_pages[i]),
                              path: _pages[i],
                            ),
                            selected: {_selectedPage},
                            onSelect: (i) => setState(() => _selectedPage = i),
                            onMove: (from, to) {
                              if (_busy) return;
                              final next = [..._pages];
                              next.insert(to, next.removeAt(from));
                              _replace(next);
                            },
                            onEdit: _busy ? null : _editPage,
                            onRotate: _busy ? null : (i) => _rotate(_pages[i]),
                            onRemove: _busy
                                ? null
                                : (i) => _replace([..._pages]..removeAt(i)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                if (_android)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _scan,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 19),
                      label: const Text('Scan'),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Choose gallery images',
                  onPressed: _busy ? null : _gallery,
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy || _pages.isEmpty ? null : _save,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 19),
                    label: const Text('Save PDF'),
                  ),
                ),
              ],
            ),
          ),
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
