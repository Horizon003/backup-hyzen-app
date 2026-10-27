import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyzen_pharmd/core/storage/local_store.dart';
import 'package:hyzen_pharmd/features/academics/domain/models.dart';
import 'package:hyzen_pharmd/features/downloads/data/downloads_controller.dart';
import 'package:hyzen_pharmd/features/downloads/data/file_store.dart';
import 'package:hyzen_pharmd/features/downloads/domain/download_record.dart';

class TestStore implements FileStore {
  @override
  Future<void> discardPartial(String key) async {}
  final transfer = Completer<DownloadedFile>();
  final started = Completer<void>();
  int calls = 0;
  final deleted = <String>[];
  bool cleared = false;
  @override
  bool get supported => true;
  @override
  Future<DownloadedFile> download(
    String url,
    String key,
    ProgressCb progress, {
    bool Function()? cancelled,
  }) {
    calls++;
    if (!started.isCompleted) started.complete();
    return transfer.future;
  }

  @override
  Future<DownloadedFile> importPreview(String path, String key) =>
      Future.value(DownloadedFile(path, 0));

  @override
  Future<bool> exists(String path) async => true;
  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
  }
}

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('hyzen-download-test-');
    Hive.init(temp.path);
    await Hive.openBox<String>(Boxes.downloads);
  });
  tearDown(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });
  const file = FileRef(
    kind: LibraryKind.notes,
    title: 'Notes',
    url: 'https://example.org/a.pdf',
  );
  test('simultaneous saves share one transfer', () async {
    final store = TestStore();
    final container = ProviderContainer(
      overrides: [fileStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(downloadsProvider.notifier);
    final first = ctrl.save(file), second = ctrl.save(file);
    expect(identical(first, second), isTrue);
    await store.started.future;
    expect(store.calls, 1);
    store.transfer.complete(const DownloadedFile('/private/a.pdf', 50));
    await first;
    expect(container.read(downloadsProvider).values.single.isReady, isTrue);
  });
  test('delete during transfer cannot recreate metadata or file', () async {
    final store = TestStore();
    final container = ProviderContainer(
      overrides: [fileStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(downloadsProvider.notifier);
    final transfer = ctrl.save(file);
    final failure = expectLater(transfer, throwsException);
    await store.started.future;
    final key = container.read(downloadsProvider).keys.single;
    final removing = ctrl.remove(key);
    store.transfer.complete(const DownloadedFile('/private/a.pdf', 50));
    await removing;
    await failure;
    expect(store.deleted, contains('/private/a.pdf'));
    expect(container.read(downloadsProvider), isEmpty);
    expect(JsonBox(Boxes.downloads).values(), isEmpty);
  });
  test('clear all settles active transfers before clearing storage', () async {
    final store = TestStore();
    final container = ProviderContainer(
      overrides: [fileStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(downloadsProvider.notifier);
    final transfer = ctrl.save(file);
    final failure = expectLater(transfer, throwsException);
    await store.started.future;
    final clearing = ctrl.removeAll();
    store.transfer.complete(const DownloadedFile('/private/a.pdf', 50));
    await clearing;
    await failure;
    expect(store.cleared, isTrue);
    expect(container.read(downloadsProvider), isEmpty);
  });
}
