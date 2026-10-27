import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/content/data/content_source.dart';

class CachedSource extends LegacyContentSource {
  CachedSource() : super(null, online: false);
  final server = Completer<ContentSnapshot>();
  @override
  Future<ContentSnapshot?> cached(String key) async =>
      ContentSnapshot(value: 'old', fromCache: true, fetchedAt: DateTime.now());
  @override
  Future<ContentSnapshot> fetch(String key) => server.future;
}

void main() {
  tearDown(forcedRefresh.clear);
  test(
    'forced refresh waits for the server instead of completing with stale data',
    () async {
      final source = CachedSource();
      final container = ProviderContainer(
        overrides: [contentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      forcedRefresh.add('pw_notes_tree');
      var completed = false;
      final result = container
          .read(contentProvider('pw_notes_tree').future)
          .then((v) {
            completed = true;
            return v;
          });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      source.server.complete(
        const ContentSnapshot(value: 'new', fromCache: false),
      );
      expect((await result).value, 'new');
    },
  );
  test('failed forced refresh falls back to the cached content', () async {
    final source = CachedSource();
    final container = ProviderContainer(
      overrides: [contentSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    forcedRefresh.add('pw_notes_tree');
    final result = container.read(contentProvider('pw_notes_tree').future);
    await Future<void>.delayed(Duration.zero);
    source.server.completeError(StateError('offline'));
    final cached = await result;
    expect(cached.value, 'old');
    expect(cached.fromCache, isTrue);
  });
}
