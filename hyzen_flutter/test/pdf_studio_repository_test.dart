import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyzen_pharmd/core/storage/local_store.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/pdf_studio_repository.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/studio_storage.dart';

class _MemoryStudioStorage implements StudioStorage {
  final deleted = <String>[];

  @override
  Future<StoredStudioFile> importCopy(String sourcePath, String id) async =>
      StoredStudioFile(
        path: '/workspace/$id.pdf',
        editStatePath: '/workspace/state/${id}_state.json',
        sizeBytes: 2048,
        extension: 'pdf',
      );

  @override
  Future<void> deleteStored({
    required String path,
    required String editStatePath,
  }) async {
    deleted.add(path);
    deleted.add(editStatePath);
  }

  @override
  Future<bool> exists(String path) async => true;
}

void main() {
  late Directory temp;
  late ProviderContainer container;
  late _MemoryStudioStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('hyzen-pdf-studio-test-');
    Hive.init(temp.path);
    await Hive.openBox<String>(Boxes.pdfStudioHistory);
    storage = _MemoryStudioStorage();
    container = ProviderContainer(
      overrides: [studioStorageProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test('Studio workspace supports import, rename, star, open and delete', () async {
    final repository = container.read(pdfStudioHistoryProvider.notifier);
    final file = await repository.importFile(
      '/incoming/lecture.pdf',
      originalFileName: 'lecture.pdf',
    );
    expect(container.read(pdfStudioHistoryProvider), hasLength(1));
    expect(file.fileCategory, 'PDF');
    expect(file.sourceType, 'EXTERNAL_INTENT');

    await repository.rename(file.id, 'Lecture final');
    await repository.setStarred(file.id, true);
    await repository.recordOpen(file.id, page: 7);
    final updated = container.read(pdfStudioHistoryProvider).single;
    expect(updated.displayName, 'Lecture final.pdf');
    expect(updated.isStarred, isTrue);
    expect(updated.lastOpenedPage, 7);
    expect(updated.lastOpenedAt, isNotNull);

    await repository.delete(file.id);
    expect(container.read(pdfStudioHistoryProvider), isEmpty);
    expect(storage.deleted, contains('/workspace/${file.id}.pdf'));
  });
}
