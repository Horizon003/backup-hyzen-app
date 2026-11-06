import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/storage/local_store.dart';
import '../../core/utils/media_upload.dart';
import '../../core/widgets/common.dart';
import 'offline_pdf.dart';
import 'reader_chrome.dart';
import 'document_flow.dart';
import '../pdf_studio/data/pdf_studio_repository.dart';

class ExternalDocument {
  const ExternalDocument(this.id, this.title, this.path, this.openedAt);
  final String id, title, path;
  final DateTime openedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'path': path,
    'openedAt': openedAt.toIso8601String(),
  };

  static ExternalDocument? fromMap(Map<String, dynamic> map) {
    final id = map['id'], path = map['path'];
    if (id is! String || path is! String) return null;
    return ExternalDocument(
      id,
      map['title'] as String? ?? 'Document',
      path,
      DateTime.tryParse('${map['openedAt']}') ?? DateTime.now(),
    );
  }
}

class ExternalHistory extends Notifier<List<ExternalDocument>> {
  JsonBox get _box => JsonBox(Boxes.externalHistory);

  @override
  List<ExternalDocument> build() {
    final items = _box
        .values()
        .map(ExternalDocument.fromMap)
        .whereType<ExternalDocument>()
        .toList();
    items.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return items;
  }

  Future<void> add(ExternalDocument item) async {
    await _box.put(item.id, item.toMap());
    state = [item, ...state.where((old) => old.id != item.id)];
  }

  Future<void> delete(ExternalDocument item) async {
    await _box.delete(item.id);
    state = state.where((old) => old.id != item.id).toList();
    if (!kIsWeb) {
      try {
        await const MethodChannel(
          'com.hyzen.pharmd/external_files',
        ).invokeMethod<bool>('deleteImport', {'path': item.path});
      } catch (_) {}
    }
  }
}

final externalHistoryProvider =
    NotifierProvider<ExternalHistory, List<ExternalDocument>>(
      ExternalHistory.new,
    );

/// Keep the Android incoming intent until Firebase completes authentication.
class ExternalOpenGate extends ConsumerStatefulWidget {
  const ExternalOpenGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ExternalOpenGate> createState() => _ExternalOpenGateState();
}

class _ExternalOpenGateState extends ConsumerState<ExternalOpenGate>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.hyzen.pharmd/external_files');
  static const _camera = MethodChannel('com.hyzen.pharmd/camera_pages');
  static const _session = MethodChannel('com.hyzen.pharmd/session');
  bool _draining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _session.setMethodCallHandler((call) async {
        if (call.method == 'launcherOpened' && mounted) {
          ref.read(sessionRevisionProvider.notifier).state++;
          ref.read(routerProvider).go('/home');
        }
      });
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'incomingStarted') {
          ref.read(documentHandoffProvider.notifier).state = true;
        }
        if (call.method == 'incomingAvailable') await _drain();
      });
      _camera.setMethodCallHandler((call) async {
        if (call.method == 'draftReady') {
          ref.read(documentDraftRevisionProvider.notifier).state++;
          await _recoverCamera();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(documentHandoffProvider.notifier).state = false;
      });
    }
  }

  Future<void> _drain() async {
    if (_draining || !mounted) {
      return;
    }
    _draining = true;
    try {
      final items =
          await _channel.invokeListMethod<dynamic>('takePending') ?? [];
      for (final value in items) {
        if (!mounted || value is! Map) break;
        final item = Map<String, dynamic>.from(value);
        if (item['error'] is String) {
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(item['error'] as String)));
          continue;
        }
        final id = item['id'], path = item['path'], title = item['title'];
        if (id is! String || path is! String || title is! String) continue;
        final document = ExternalDocument(id, title, path, DateTime.now());
        await ref.read(externalHistoryProvider.notifier).add(document);
        if (mounted) {
          ref
              .read(routerProvider)
              .push('/imported-viewer?id=${document.id}', extra: document);
        }
      }
      // Drafts are recovered when Office is opened; cold launch stays on Home.
    } catch (_) {
      // Native channel is absent on web/test platforms.
    } finally {
      _draining = false;
      try {
        final importing =
            await _channel.invokeMethod<bool>('isImporting') ?? false;
        if (mounted) {
          ref.read(documentHandoffProvider.notifier).state = importing;
        }
      } catch (_) {
        if (mounted) ref.read(documentHandoffProvider.notifier).state = false;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _drain();
  }

  Future<void> _recoverCamera() async {
    try {
      final router = ref.read(routerProvider);
      if (router.routeInformationProvider.value.uri.path == '/create-pdf') {
        return;
      }
      final recover = await _camera.invokeMethod<bool>('needsRecovery');
      if (mounted && recover == true) router.go('/create-pdf');
    } catch (_) {
      /* Optional native draft bridge. */
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
      }
    });
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _session.setMethodCallHandler(null);
      _channel.setMethodCallHandler(null);
      _camera.setMethodCallHandler(null);
    }
    super.dispose();
  }
}

class ImportedViewerScreen extends ConsumerStatefulWidget {
  const ImportedViewerScreen({super.key, required this.document});
  final ExternalDocument? document;

  @override
  ConsumerState<ImportedViewerScreen> createState() =>
      _ImportedViewerScreenState();
}

class _ImportedViewerScreenState extends ConsumerState<ImportedViewerScreen> {
  final _tools = ReaderTools();
  bool _saving = false;
  String? _savedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _findSaved());
  }

  Future<void> _findSaved() async {
    final doc = widget.document;
    if (doc == null) return;
    final prefs = ref.read(sharedPrefsProvider);
    final files = ref.read(pdfStudioHistoryProvider);
    final linked = prefs.getString('external_studio_${doc.id}');
    for (final file in files) {
      if (file.id == linked &&
          await ref.read(studioStorageProvider).exists(file.internalFilePath)) {
        if (mounted) setState(() => _savedId = file.id);
        if (mounted) context.replace('/pdf-studio/viewer/${file.id}');
        return;
      }
    }
    for (final file in files.where((f) => f.originalFileName == doc.title)) {
      try {
        final hash = await const MethodChannel(
          'com.hyzen.pharmd/external_files',
        ).invokeMethod<String>('fingerprint', {'path': file.internalFilePath});
        if (hash == doc.id) {
          await prefs.setString('external_studio_${doc.id}', file.id);
          if (mounted) context.replace('/pdf-studio/viewer/${file.id}');
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _saveToStudio(ExternalDocument doc) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_savedId != null) {
        context.replace('/pdf-studio/viewer/$_savedId');
        return;
      }
      final item = await ref
          .read(pdfStudioHistoryProvider.notifier)
          .importFile(
            doc.path,
            originalFileName: doc.title,
            sourceType: 'EXTERNAL_INTENT',
            operationBadge: 'IMPORTED',
          );
      await ref
          .read(sharedPrefsProvider)
          .setString('external_studio_${doc.id}', item.id);
      _savedId = item.id;
      if (mounted) {
        showHSnack(context, 'Copy saved. PDF tools are ready.');
        context.replace('/pdf-studio/viewer/${item.id}');
      }
    } catch (_) {
      if (mounted) {
        showHSnack(
          context,
          'Could not save this copy. Please retry.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    if (doc == null) {
      return const Scaffold(body: Center(child: Text('Document unavailable')));
    }
    return ReaderScaffold(
      title: doc.title,
      banner: _saving ? const LinearProgressIndicator(minHeight: 2) : null,
      onShare: () => MediaUpload.shareDocument(
        doc.path,
        doc.title,
        'application/octet-stream',
      ),
      actions: [
        ReaderAction(
          'Save copy & enable tools',
          Icons.save_as_outlined,
          () => _saveToStudio(doc),
        ),
        ReaderAction(
          'Save As',
          Icons.save_alt_rounded,
          () => MediaUpload.exportDocument(
            doc.path,
            doc.title,
            'application/octet-stream',
          ),
        ),
        ReaderAction(
          'Pages view',
          Icons.grid_view_rounded,
          () => _tools.run('pages', context),
        ),
        ReaderAction(
          'Search',
          Icons.search_rounded,
          () => _tools.run('search', context),
        ),
        ReaderAction(
          'Zoom in',
          Icons.zoom_in_rounded,
          () => _tools.run('in', context),
        ),
        ReaderAction(
          'Zoom out',
          Icons.zoom_out_rounded,
          () => _tools.run('out', context),
        ),
      ],
      child: OfflinePdf(path: doc.path, tools: _tools),
    );
  }
}
