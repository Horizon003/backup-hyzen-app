import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hive boxes used by the app (all device-local, never synced).
class Boxes {
  Boxes._();
  static const contentCache =
      'content_cache_v1'; // offline METADATA cache (legacy settings/{key} values)
  static const downloads = 'downloads_v1'; // offline DOCUMENT metadata
  static const recent = 'recent_v1'; // continue-learning history
  static const externalHistory =
      'external_history_v1'; // user-opened device files
  static const pdfStudioHistory =
      'pdf_studio_history_v1'; // private PDF Studio workspace metadata
  static const cart = 'cart_v1'; // device-local cart (legacy pw_cart semantics)
  static const myOrders = 'my_orders_v1'; // orders placed on this device

  static Future<void> init() async {
    await Hive.initFlutter('hyzen');
    await Future.wait([
      Hive.openBox<String>(contentCache),
      Hive.openBox<String>(downloads),
      Hive.openBox<String>(recent),
      Hive.openBox<String>(externalHistory),
      Hive.openBox<String>(pdfStudioHistory),
      Hive.openBox<String>(cart),
      Hive.openBox<String>(myOrders),
    ]);
  }
}

/// JSON map stored as String in a Hive box (avoids TypeAdapters & codegen).
class JsonBox {
  JsonBox(this.name);
  final String name;
  Box<String> get _b => Hive.box<String>(name);

  Map<String, dynamic>? get(String key) {
    final s = _b.get(key);
    if (s == null) return null;
    try {
      return (jsonDecode(s) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> put(String key, Map<String, dynamic> v) =>
      _b.put(key, jsonEncode(v));
  Future<void> delete(String key) => _b.delete(key);
  Iterable<String> get keys => _b.keys.cast<String>();
  List<Map<String, dynamic>> values() =>
      keys.map(get).whereType<Map<String, dynamic>>().toList(growable: false);
  Future<void> clear() => _b.clear();
  Stream<BoxEvent> watch() => _b.watch();
}

/// Registration recovery: if Firebase Auth succeeded but students/{uid} could not be
/// written (offline / rules not deployed), the profile (NO password) is kept here and retried.
class PendingProfileStore {
  PendingProfileStore(this._prefs);
  final SharedPreferences _prefs;
  String _k(String uid) => 'pending_profile_$uid';
  String _cacheKey(String uid) => 'student_profile_cache_$uid';
  Map<String, dynamic>? cached(String uid) {
    final raw = _prefs.getString(_cacheKey(uid));
    if (raw == null) return read(uid);
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return read(uid);
    }
  }

  Future<void> cache(String uid, Map<String, dynamic> m) =>
      _prefs.setString(_cacheKey(uid), jsonEncode(m));

  Map<String, dynamic>? read(String uid) {
    final s = _prefs.getString(_k(uid));
    if (s == null) return null;
    try {
      return (jsonDecode(s) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String uid, Map<String, dynamic> m) async {
    await cache(uid, m);
    await _prefs.setString(_k(uid), jsonEncode(m));
  }

  Future<void> clear(String uid) => _prefs.remove(_k(uid));
}
