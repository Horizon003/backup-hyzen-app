class StoredStudioFile {
  const StoredStudioFile({
    required this.path,
    required this.editStatePath,
    required this.sizeBytes,
    required this.extension,
  });

  final String path;
  final String editStatePath;
  final int sizeBytes;
  final String extension;
}

abstract interface class StudioStorage {
  Future<StoredStudioFile> importCopy(String sourcePath, String id);
  Future<void> deleteStored({
    required String path,
    required String editStatePath,
  });
  Future<bool> exists(String path);
}
