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
  bool available = true;
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
  Future<bool> exists(String path) async => available;
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
  test('HOME-10/11/12 new completion persists, successful open clears only New', () async {
    final store = TestStore();
    var container = ProviderContainer(overrides: [fileStoreProvider.overrideWithValue(store)]);
    final ctrl = container.read(downloadsProvider.notifier);
    final transfer = ctrl.save(file);
    await store.started.future;
    store.transfer.complete(const DownloadedFile('/private/a.pdf', 50));
    await transfer;
    var record = container.read(downloadsProvider).values.single;
    expect(record.unopened, isTrue);
    expect(record.firstOpenedAt, isNull);
    expect(record.isAvailableOffline, isTrue);
    final key = record.key;
    final savedAt = record.savedAt;
    container.dispose();
    container = ProviderContainer(overrides: [fileStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    expect(container.read(downloadsProvider)[key]!.unopened, isTrue);
    await Future<void>.delayed(Duration.zero);
    await container.read(downloadsProvider.notifier).markOpened(key, path: '/private/a.pdf', savedAt: savedAt);
    record = container.read(downloadsProvider)[key]!;
    expect(record.unopened, isFalse);
    expect(record.firstOpenedAt, isNotNull);
    expect(record.isAvailableOffline, isTrue);
    expect(record.savedAt, savedAt);
    expect(record.sizeBytes, 50);
    final openedAt = record.firstOpenedAt;
    await container.read(downloadsProvider.notifier).markOpened(key, path: '/private/a.pdf', savedAt: savedAt);
    expect(container.read(downloadsProvider)[key]!.firstOpenedAt, openedAt);
    final restored = DownloadRecord.fromMap(JsonBox(Boxes.downloads).values().single)!;
    expect(restored.firstOpenedAt, openedAt);
    expect(restored.unopened, isFalse);
  });
  test('HOME-11 failed and stale opens never clear unopened state', () async {
    final store = TestStore();
    final container = ProviderContainer(overrides: [fileStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    final ctrl = container.read(downloadsProvider.notifier);
    final transfer = ctrl.save(file);
    await store.started.future;
    store.transfer.complete(const DownloadedFile('/private/a.pdf', 50));
    await transfer;
    final r = container.read(downloadsProvider).values.single;
    await ctrl.markOpened(r.key, path: '/private/wrong.pdf', savedAt: r.savedAt);
    await ctrl.markOpened(r.key, path: r.localPath!, savedAt: DateTime(2000));
    store.available = false;
    await ctrl.markOpened(r.key, path: r.localPath!, savedAt: r.savedAt);
    expect(container.read(downloadsProvider)[r.key]!.unopened, isTrue);
    expect(container.read(downloadsProvider)[r.key]!.firstOpenedAt, isNull);
  });
  test('HOME-12 legacy ready downloads migrate without a New badge', () {
    final record = DownloadRecord.fromMap({'key': 'legacy', 'status': 'ready', 'localPath': '/private/old.pdf'})!;
    expect(record.isReady, isTrue);
    expect(record.unopened, isFalse);
    expect(record.firstOpenedAt, isNull);
    expect(record.isAvailableOffline, isFalse, reason: 'Restored metadata waits for a real file existence check');
  });

}

