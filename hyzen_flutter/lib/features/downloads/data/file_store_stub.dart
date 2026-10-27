import '../../../core/errors/app_error.dart';
import 'file_store.dart';

FileStore createFileStore() => _WebFileStore();

/// Website/web preview: Save Offline is app-only (CONFIRMED product rule).
class _WebFileStore implements FileStore {
  @override
  Future<void> discardPartial(String key) async {}
  @override
  bool get supported => false;
  @override
  Future<DownloadedFile> download(
    String url,
    String key,
    ProgressCb onProgress, {
    bool Function()? cancelled,
  }) => throw FriendlyException(
    'Save Offline is available in the Hyzen Android app.',
  );
  @override
  Future<DownloadedFile> importPreview(String path, String key) =>
      throw FriendlyException(
        'Save Offline is available in the Hyzen Android app.',
      );
  @override
  Future<bool> exists(String path) async => false;
  @override
  Future<void> delete(String path) async {}
  @override
  Future<void> clearAll() async {}
}
