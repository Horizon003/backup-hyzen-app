import 'studio_storage_contract.dart';

StudioStorage createStudioStorage() => _UnsupportedStudioStorage();

class _UnsupportedStudioStorage implements StudioStorage {
  @override
  Future<StoredStudioFile> importCopy(String sourcePath, String id) =>
      Future.error(UnsupportedError('Office Workspace file storage requires Android.'));

  @override
  Future<void> deleteStored({
    required String path,
    required String editStatePath,
  }) async {}

  @override
  Future<bool> exists(String path) async => false;
}
