import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class OcrDocumentIndex {
  const OcrDocumentIndex({required this.id, required this.name, required this.pages});

  final String id;
  final String name;
  final List<String> pages;

  Map<String, Object> toMap() => {'name': name, 'pages': pages};

  static OcrDocumentIndex? fromMap(String id, dynamic raw) {
    if (raw is! Map || raw['name'] is! String || raw['pages'] is! List) return null;
    final pages = [
      for (final page in raw['pages'] as List)
        if (page is String) page,
    ];
    return OcrDocumentIndex(id: id, name: raw['name'] as String, pages: pages);
  }
}

class OcrSearchResult {
  const OcrSearchResult({
    required this.documentId,
    required this.documentName,
    required this.page,
    required this.snippet,
  });

  final String documentId;
  final String documentName;
  final int page;
  final String snippet;
}

final ocrIndexProvider =
    NotifierProvider<OcrIndexNotifier, Map<String, OcrDocumentIndex>>(
  OcrIndexNotifier.new,
);

class OcrIndexNotifier extends Notifier<Map<String, OcrDocumentIndex>> {
  static const _key = 'ocr_index_v1';

  @override
  Map<String, OcrDocumentIndex> build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String)
            if (OcrDocumentIndex.fromMap(entry.key as String, entry.value)
                case final index?)
              entry.key as String: index,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> save({
    required String documentId,
    required String documentName,
    required List<String> pages,
  }) async {
    final cleaned = [
      for (final page in pages)
        page.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];
    final next = {
      ...state,
      documentId: OcrDocumentIndex(
        id: documentId,
        name: documentName,
        pages: cleaned,
      ),
    };
    await _persist(next);
  }

  Future<void> rename(String documentId, String name) async {
    final existing = state[documentId];
    if (existing == null) return;
    await _persist({
      ...state,
      documentId: OcrDocumentIndex(
        id: documentId,
        name: name,
        pages: existing.pages,
      ),
    });
  }

  Future<void> invalidate(String documentId) async {
    if (!state.containsKey(documentId)) return;
    final next = {...state}..remove(documentId);
    await _persist(next);
  }

  List<OcrSearchResult> search(String query, {int limit = 40}) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];
    final results = <OcrSearchResult>[];
    for (final document in state.values) {
      for (var i = 0; i < document.pages.length; i++) {
        final text = document.pages[i];
        final lower = text.toLowerCase();
        if (!terms.every(lower.contains)) continue;
        final first = lower.indexOf(terms.first);
        final start = (first < 45 ? 0 : first - 45).clamp(0, text.length);
        final end = (start + 150).clamp(start, text.length);
        final snippet = text.substring(start, end).trim();
        results.add(
          OcrSearchResult(
            documentId: document.id,
            documentName: document.name,
            page: i + 1,
            snippet: snippet.isEmpty ? 'Matched OCR text' : snippet,
          ),
        );
        if (results.length >= limit) return results;
      }
    }
    return results;
  }

  Future<void> _persist(Map<String, OcrDocumentIndex> next) async {
    state = Map.unmodifiable(next);
    await ref.read(sharedPrefsProvider).setString(
          _key,
          jsonEncode({for (final entry in state.entries) entry.key: entry.value.toMap()}),
        );
  }
}
