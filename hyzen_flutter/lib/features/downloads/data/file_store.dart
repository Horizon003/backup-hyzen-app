import 'file_store_stub.dart' if (dart.library.io) 'file_store_io.dart' as impl;

typedef ProgressCb = void Function(int received, int? total);

class DownloadedFile {
  const DownloadedFile(this.path, this.size);
  final String path;
  final int size;
}

/// Platform file storage for offline documents (app-specific directory only).
abstract class FileStore {
  bool get supported;
  Future<DownloadedFile> download(
    String url,
    String key,
    ProgressCb onProgress, {
    bool Function()? cancelled,
  });
  Future<bool> exists(String path);
  Future<void> delete(String path);
  Future<void> clearAll();
  Future<void> discardPartial(String key) async {}

  /// Reuse a validated temporary reader copy where the native store supports it.
  Future<DownloadedFile> importPreview(String path, String key) =>
      throw UnsupportedError('Local preview import is unavailable.');

  static FileStore create() => impl.createFileStore();
}
