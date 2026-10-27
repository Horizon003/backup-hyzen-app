import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import 'studio_file_item.dart';
import 'studio_storage.dart';

final studioStorageProvider = Provider<StudioStorage>(
  (_) => createStudioStorage(),
);

final pdfStudioHistoryProvider =
    NotifierProvider<PdfStudioRepository, List<StudioFileItem>>(
      PdfStudioRepository.new,
    );

class PdfStudioRepository extends Notifier<List<StudioFileItem>> {
  JsonBox get _box => JsonBox(Boxes.pdfStudioHistory);
  StudioStorage get _storage => ref.read(studioStorageProvider);

  @override
  List<StudioFileItem> build() => _sorted(
    _box.values()
        .map(StudioFileItem.fromMap)
        .whereType<StudioFileItem>()
        .toList(),
  );

  List<StudioFileItem> _sorted(List<StudioFileItem> items) {
    items.sort((a, b) {
      final aDate = a.lastOpenedAt ?? a.updatedAt;
      final bDate = b.lastOpenedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });
    return List.unmodifiable(items);
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _category(String ext) => switch (ext) {
    'pdf' => 'PDF',
    'txt' || 'md' || 'rtf' => 'DOC',
    'jpg' || 'jpeg' || 'png' || 'webp' => 'IMAGE_SCAN',
    _ => 'DOC',
  };

  Future<StudioFileItem> importFile(
    String sourcePath, {
    String? originalFileName,
    String? displayName,
    String sourceType = 'EXTERNAL_INTENT',
    String operationBadge = 'IMPORTED',
  }) async {
    final id = _uuid();
    final stored = await _storage.importCopy(sourcePath, id);
    final name = originalFileName?.trim().isNotEmpty == true
        ? originalFileName!.trim()
        : sourcePath.split('/').last;
    final now = DateTime.now();
    final item = StudioFileItem(
      id: id,
      originalFileName: name,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : name,
      internalFilePath: stored.path,
      editStateJsonPath: stored.editStatePath,
      sourceType: sourceType,
      fileCategory: _category(stored.extension),
      fileSizeBytes: stored.sizeBytes,
      createdAt: now,
      updatedAt: now,
      operationBadge: operationBadge,
    );
    await _box.put(id, item.toMap());
    state = _sorted([item, ...state]);
    return item;
  }

  Future<void> rename(String id, String name) async {
    final item = _find(id);
    if (item == null) return;
    var cleaned = name.trim();
    if (cleaned.isEmpty) return;
    final extension = item.internalFilePath.split('.').last.toLowerCase();
    if (!cleaned.toLowerCase().endsWith('.$extension')) {
      cleaned = '$cleaned.$extension';
    }
    final updated = item.copyWith(displayName: cleaned, updatedAt: DateTime.now());
    await _save(updated);
  }

  Future<void> setStarred(String id, bool starred) async {
    final item = _find(id);
    if (item == null) return;
    await _save(item.copyWith(isStarred: starred, updatedAt: DateTime.now()));
  }

  Future<void> markEdited(String id) async {
    final item = _find(id);
    if (item == null) return;
    await _save(item.copyWith(operationBadge: 'EDITED', updatedAt: DateTime.now()));
  }

  Future<void> recordOpen(String id, {int? page}) async {
    final item = _find(id);
    if (item == null) return;
    final updated = item.copyWith(
      lastOpenedAt: DateTime.now(),
      lastOpenedPage: page == null || page < 1 ? item.lastOpenedPage : page,
    );
    await _save(updated);
  }

  Future<void> updatePageCount(String id, int pageCount) async {
    final item = _find(id);
    if (item == null || pageCount < 0) return;
    await _save(item.copyWith(pageCount: pageCount));
  }

  Future<void> delete(String id) async {
    final item = _find(id);
    if (item == null) return;
    await _storage.deleteStored(
      path: item.internalFilePath,
      editStatePath: item.editStateJsonPath,
    );
    await _box.delete(id);
    state = state.where((file) => file.id != id).toList(growable: false);
  }

  Future<void> _save(StudioFileItem item) async {
    await _box.put(item.id, item.toMap());
    state = _sorted([
      for (final old in state) if (old.id == item.id) item else old,
    ]);
  }

  StudioFileItem? _find(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }
}
