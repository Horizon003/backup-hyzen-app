import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/storage/local_store.dart';

/// A legacy `pw_*` value read from `settings/{key}` (CONFIRMED storage model:
/// one Firestore document per key, shape `{value, updatedAt}`).
class ContentSnapshot {
  const ContentSnapshot({
    required this.value,
    required this.fromCache,
    this.fetchedAt,
    this.exists = true,
  });
  final Object? value;
  final bool fromCache;
  final bool exists;
  final DateTime? fetchedAt;
}

/// Public keys the app may read (CONFIRMED PUBLIC_KEYS + pw_special_tree).
const publicContentKeys = {
  'pw_settings',
  'pw_notes_tree',
  'pw_lectures_tree',
  'pw_mcqs_tree',
  'pw_special_tree',
  'pw_pastpapers',
  'pw_products',
  'pw_blogs',
  'pw_announcement',
  'pw_catalog_settings',
  'pw_delivery',
  'pw_stats',
  'pw_social',
  'pw_credits',
  'pw_about',
};

/// Cached copies younger than this are used without re-downloading (big trees are 1–2 MB).
const contentFreshFor = Duration(minutes: 15);

Object? _decode(String s) => jsonDecode(s);
String _encode(Object? v) => jsonEncode(v);

/// Read-only adapter. The app NEVER writes to `settings/*` (admin-only).
class LegacyContentSource {
  LegacyContentSource(this._db, {required this.online});
  final FirebaseFirestore? _db;
  final bool online;
  Box<String> get _box => Hive.box<String>(Boxes.contentCache);

  /// JSON decode happens off the UI thread (isolate on Android).
  Future<ContentSnapshot?> cached(String key) async {
    final s = _box.get(key);
    if (s == null) return null;
    try {
      final m = (await compute(_decode, s)) as Map;
      return ContentSnapshot(
        value: m['value'],
        fromCache: true,
        exists: m['exists'] != false,
        fetchedAt: DateTime.tryParse('${m['fetchedAt']}'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ContentSnapshot> fetch(String key) async {
    final db = _db;
    if (db == null || !online) throw StateError('offline');
    final snap = await db
        .collection('settings')
        .doc(key)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    final data = snap.data();
    final exists = snap.exists && data != null && data.containsKey('value');
    final value = exists ? data['value'] : null;
    final now = DateTime.now();
    unawaited(() async {
      try {
        final raw = await compute(_encode, {
          'value': value,
          'exists': exists,
          'fetchedAt': now.toIso8601String(),
        });
        await _box.put(key, raw);
      } catch (_) {}
    }());
    return ContentSnapshot(
      value: value,
      fromCache: false,
      exists: exists,
      fetchedAt: now,
    );
  }
}

final contentSourceProvider = Provider<LegacyContentSource>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  return LegacyContentSource(
    ready ? ref.watch(firestoreProvider) : null,
    online: ready,
  );
});

/// Keys the user explicitly asked to refresh (pull-to-refresh) — bypass freshness.
final forcedRefresh = <String>{};

/// Stale-while-revalidate with a freshness window. Errors surface only when nothing is cached.
final contentProvider = StreamProvider.family<ContentSnapshot, String>((
  ref,
  key,
) async* {
  final src = ref.watch(contentSourceProvider);
  final force = forcedRefresh.remove(key);
  final c = await src.cached(key);
  if (c != null && !force) {
    yield c;
    final age = c.fetchedAt == null
        ? null
        : DateTime.now().difference(c.fetchedAt!);
    if (key != 'pw_settings' &&
        key != 'pw_announcement' &&
        !force &&
        age != null &&
        age < contentFreshFor) {
      return;
    }
  }
  try {
    if ((key == 'pw_settings' || key == 'pw_announcement') &&
        ref.read(firebaseReadyProvider)) {
      await for (final snap
          in ref
              .read(firestoreProvider)
              .collection('settings')
              .doc(key)
              .snapshots(includeMetadataChanges: true)) {
        final data = snap.data();
        final now = DateTime.now();
        final value = data?['value'];
        final exists = snap.exists && data != null && data.containsKey('value');
        final raw = await compute(_encode, {
          'value': value,
          'exists': exists,
          'fetchedAt': now.toIso8601String(),
        });
        await Hive.box<String>(Boxes.contentCache).put(key, raw);
        yield ContentSnapshot(
          value: value,
          fromCache: snap.metadata.isFromCache,
          exists: exists,
          fetchedAt: now,
        );
      }
      return;
    }
    yield await src.fetch(key);
  } catch (e) {
    if (kDebugMode) debugPrint('content $key fetch failed: $e');
    if (c == null) throw ContentUnavailable(key, e);
    if (force) yield c;
  }
});

class ContentUnavailable implements Exception {
  ContentUnavailable(this.key, this.cause);
  final String key;
  final Object cause;
  @override
  String toString() =>
      'Content is unavailable right now. Check your connection and try again.';
}

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
List<Map<String, dynamic>> asMapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : <Map<String, dynamic>>[];
