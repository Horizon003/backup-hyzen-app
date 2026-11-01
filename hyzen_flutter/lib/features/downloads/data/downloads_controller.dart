import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/local_store.dart';
import '../../academics/domain/drive.dart';
import '../domain/download_record.dart';
import 'file_store.dart';

final fileStoreProvider = Provider<FileStore>((_) => FileStore.create());
final downloadsBoxProvider = Provider<JsonBox>((_) => JsonBox(Boxes.downloads));

class DownloadsController extends Notifier<Map<String, DownloadRecord>> {
  final _cancel = <String>{};
  final _removing = <String>{};
  final _jobs = <String, Future<void>>{};
  bool _clearing = false, _disposed = false;
  JsonBox get _box => ref.read(downloadsBoxProvider);
  FileStore get _fs => ref.read(fileStoreProvider);

  @override
  Map<String, DownloadRecord> build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _cancel.addAll(_jobs.keys);
    });
    final map = <String, DownloadRecord>{};
    for (final value in ref.read(downloadsBoxProvider).values()) {
      final record = DownloadRecord.fromMap(value);
      if (record == null) continue;
      map[record.key] = record.status == DownloadStatus.downloading
          ? record.copyWith(
              status: DownloadStatus.paused,
              error: 'Tap Resume to continue.',
            )
          : record;
    }
    // Defer until Notifier.state is initialized.
    unawaited(Future<void>(() => _verifyFiles(map)));
    return map;
  }

  Future<void> _verifyFiles(Map<String, DownloadRecord> map) async {
    if (_disposed) return;
    final store = _fs;
    for (final r in map.values.where((r) => r.isReady)) {
      final exists = await store.exists(r.localPath!);
      if (_disposed) return;
      if (exists && identical(state[r.key], r)) {
        state = {...state, r.key: r.copyWith(availabilityVerified: true)};
      }
      if (!exists &&
          identical(state[r.key], r) &&
          !_removing.contains(r.key) &&
          !_clearing) {
        await _set(
          r.copyWith(
            status: DownloadStatus.failed,
            error: 'Local file is missing. Save it again.',
          ),
        );
      }
    }
  }

  Future<void> _set(DownloadRecord r) async {
    if (_disposed) return;
    state = {...state, r.key: r};
    await _box.put(r.key, r.toMap());
  }

  /// Called only after a renderer successfully opens this exact saved version.
  Future<void> markOpened(
    String key, {
    required String path,
    required DateTime? savedAt,
  }) async {
    final initial = state[key];
    if (initial == null ||
        !initial.isReady ||
        !initial.unopened ||
        initial.localPath != path ||
        initial.savedAt != savedAt) {
      return;
    }
    if (!await _fs.exists(path) || _disposed) return;
    final current = state[key];
    if (current == null ||
        !current.isReady ||
        !current.unopened ||
        current.localPath != path ||
        current.savedAt != savedAt ||
        _removing.contains(key) ||
        _clearing) {
      return;
    }
    await _set(
      current.copyWith(
        unopened: false,
        firstOpenedAt: DateTime.now(),
        availabilityVerified: true,
      ),
    );
  }

  DownloadRecord? recordFor(String url) => state[DriveLinks.offlineKey(url)];

  Future<void> save(FileRef file, {String? localPreview}) {
    final key = DriveLinks.offlineKey(file.url);
    if (_clearing || _removing.contains(key)) {
      return Future.error(
        FriendlyException('Downloads are being removed. Please wait.'),
      );
    }
    final current = _jobs[key];
    if (current != null) return current;
    if (state[key]?.isReady == true) return Future.value();
    if (!_fs.supported) {
      return Future.error(
        FriendlyException(
          'Save Offline is available in the Hyzen Android app.',
        ),
      );
    }
    final uri = Uri.tryParse(file.url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return Future.error(
        FriendlyException(
          'This file does not have a valid HTTPS download link.',
        ),
      );
    }
    _cancel.remove(key);
    // Register synchronously before another save can create a second transfer.
    final done = Completer<void>();
    _jobs[key] = done.future;
    () async {
      try {
        await _download(file, key, localPreview: localPreview);
        done.complete();
      } catch (e, st) {
        done.completeError(e, st);
      } finally {
        _jobs.remove(key);
        _cancel.remove(key);
      }
    }();
    return done.future;
  }

  Future<void> _download(
    FileRef file,
    String key, {
    String? localPreview,
  }) async {
    final store = _fs;
    var record = DownloadRecord(
      key: key,
      kind: file.kind,
      title: file.title,
      sourceUrl: file.url,
      status: DownloadStatus.downloading,
      trail: file.trail,
      startedAt: DateTime.now(),
    );
    var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await _set(record);
      final output = localPreview != null && await store.exists(localPreview)
          ? await store.importPreview(localPreview, key)
          : await store.download(file.url, key, (received, total) {
              if (_disposed ||
                  _cancel.contains(key) ||
                  _removing.contains(key) ||
                  _clearing) {
                return;
              }
              final now = DateTime.now();
              if (now.difference(lastEmit).inMilliseconds < 120) return;
              lastEmit = now;
              final progress = total != null && total > 0
                  ? (received / total).clamp(0.0, 1.0).toDouble()
                  : -1.0;
              record = record.copyWith(
                progress: progress,
                sizeBytes: received,
                totalBytes: total,
              );
              state = {...state, key: record};
            }, cancelled: () => _disposed || _cancel.contains(key));
      if (_disposed ||
          _cancel.contains(key) ||
          _removing.contains(key) ||
          _clearing) {
        await store.delete(output.path);
        throw FriendlyException('Download cancelled.');
      }
      record = record.copyWith(
        status: DownloadStatus.ready,
        localPath: output.path,
        sizeBytes: output.size,
        progress: 1,
        savedAt: DateTime.now(),
        unopened: true,
        availabilityVerified: true,
      );
      await _set(record);
    } catch (e) {
      final message = e is FriendlyException
          ? e.message
          : 'Download failed. Please retry.';
      if (!_disposed && !_removing.contains(key) && !_clearing) {
        await _set(
          record.copyWith(
            status: _cancel.contains(key)
                ? DownloadStatus.paused
                : DownloadStatus.failed,
            error: message,
          ),
        );
      }
      throw FriendlyException(message);
    }
  }

  void cancel(String key) => _cancel.add(key);
  Future<void> _settle(String key) async {
    try {
      await _jobs[key];
    } catch (_) {
      /* Cancellation is expected. */
    }
  }

  /// Cancel and settle before deletion so a late transfer cannot recreate a file.
  Future<void> remove(String key) async {
    if (_clearing || !_removing.add(key)) return;
    try {
      cancel(key);
      await _settle(key);
      final record = state[key];
      if (record?.localPath != null) await _fs.delete(record!.localPath!);
      await _fs.discardPartial(key);
      await _box.delete(key);
      state = {...state}..remove(key);
    } finally {
      _removing.remove(key);
    }
  }

  Future<void> removeAll() async {
    if (_clearing) return;
    _clearing = true;
    try {
      _cancel.addAll(_jobs.keys);
      await Future.wait(_jobs.keys.toList().map(_settle));
      await _fs.clearAll();
      await _box.clear();
      state = {};
    } finally {
      _clearing = false;
    }
  }

  int get totalBytes => state.values
      .where((r) => r.isReady)
      .fold(0, (sum, r) => sum + r.sizeBytes);
}

final downloadsProvider =
    NotifierProvider<DownloadsController, Map<String, DownloadRecord>>(
      DownloadsController.new,
    );
final downloadForUrlProvider = Provider.family<DownloadRecord?, String>(
  (ref, url) => ref.watch(
    downloadsProvider.select((map) => map[DriveLinks.offlineKey(url)]),
  ),
);
