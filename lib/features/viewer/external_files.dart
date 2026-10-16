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

class _ExternalOpenGateState extends ConsumerState<ExternalOpenGate> {
  static const _channel = MethodChannel('com.hyzen.pharmd/external_files');
  bool _draining = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'incomingAvailable') await _drain();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
    }
  }

  Future<void> _drain() async {
    if (_draining ||
        !mounted ||
        ref.read(authStateProvider).valueOrNull == null) {
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
          ref.read(routerProvider).push('/imported-viewer', extra: document);
        }
      }
    } catch (_) {
      // Native channel is absent on web/test platforms.
    } finally {
      _draining = false;
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler(null);
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
  bool _showSaveBanner = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    if (doc == null) {
      return const Scaffold(body: Center(child: Text('Document unavailable')));
    }
    return Scaffold(
      appBar: HTopBar(
        title: doc.title,
        actions: [
          IconButton(
            tooltip: 'Save a copy to your device',
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: () async {
              final ext = doc.path.split('.').last;
              final ok = await MediaUpload.exportDocument(
                doc.path,
                doc.title,
                ext == 'pdf' ? 'application/pdf' : 'application/octet-stream',
              );
              if (context.mounted) {
                showHSnack(context, ok ? 'File exported' : 'Export cancelled');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSaveBanner)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Theme.of(context).colorScheme.onSecondaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Read-only preview',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Save a copy to PDF Studio to keep it in your workspace and history.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => _saveToStudio(doc),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save copy'),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _showSaveBanner = false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: OfflinePdf(path: doc.path)),
        ],
      ),
    );
  }

  Future<void> _saveToStudio(ExternalDocument doc) async {
    setState(() => _saving = true);
    try {
      final item = await ref.read(pdfStudioHistoryProvider.notifier).importFile(
            doc.path,
            originalFileName: doc.title,
            sourceType: 'EXTERNAL_INTENT',
            operationBadge: 'IMPORTED',
          );
      if (!mounted) return;
      showHSnack(context, 'Saved to your PDF Studio workspace');
      context.push('/pdf-studio/viewer/${item.id}');
    } catch (_) {
      if (mounted) {
        showHSnack(context, 'Could not save this file to PDF Studio.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
