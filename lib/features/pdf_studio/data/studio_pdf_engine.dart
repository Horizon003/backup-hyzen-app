import 'dart:convert';

import 'package:flutter/services.dart';

class PickedStudioFile {
  const PickedStudioFile(this.name, this.path);
  final String name;
  final String path;
}

class StudioPage {
  StudioPage(this.path, this.index, {this.rotation = 0, this.blank = false, this.annotations = const []}) : id = _nextId++;
  StudioPage.blank() : path = '', index = 0, rotation = 0, blank = true, annotations = const [], id = _nextId++;
  StudioPage._rotated(this.path, this.index, this.rotation, this.id, this.annotations) : blank = false;
  static int _nextId = 0;
  final int id;
  final String path;
  final int index;
  final int rotation;
  final bool blank;
  final List<Map<String, dynamic>> annotations;

  StudioPage rotate() => blank ? this : StudioPage._rotated(path, index, (rotation + 90) % 360, id, annotations);

  Map<String, Object> toMap() => {
    'path': path,
    'page': index,
    'rotation': rotation,
    'blank': blank,
    'annotations': annotations,
  };
}

class StudioPdfEngine {
  static const _pdf = MethodChannel('com.hyzen.pharmd/pdf_studio');
  static const _files = MethodChannel('com.hyzen.pharmd/csv_files');

  static Future<List<PickedStudioFile>> pickFiles() async {
    final files = await _files.invokeListMethod<dynamic>('pickStudioFiles');
    return [
      for (final entry in files ?? const [])
        if (entry is Map && entry['name'] is String && entry['path'] is String)
          PickedStudioFile(entry['name'] as String, entry['path'] as String),
    ];
  }

  static Future<int> pageCount(String path) async =>
      await _pdf.invokeMethod<int>('pageCount', {'path': path}) ?? 0;

  /// Android PdfRenderer redraws these pages into a new PDF. The output is
  /// visually faithful but rasterized, so text selection is not preserved.
  static Future<String> compose(List<StudioPage> pages) async =>
      await _pdf.invokeMethod<String>('compose', {
        'pages': [for (final page in pages) page.toMap()],
      }) ?? '';

  static Future<String> imagesToPdf(List<String> paths) async =>
      await _pdf.invokeMethod<String>('imagesToPdf', {'paths': paths}) ?? '';

  static Future<String> textToPdf(String text) async =>
      await _pdf.invokeMethod<String>('textToPdf', {'text': text}) ?? '';

  static Future<String> textToDocx(String text) async =>
      await _pdf.invokeMethod<String>('textToDocx', {'text': text}) ?? '';

  static Future<String> textFile(String text) async =>
      await _pdf.invokeMethod<String>('textFile', {'text': text}) ?? '';

  static Future<String> readText(String path) async =>
      await _pdf.invokeMethod<String>('readText', {'path': path}) ?? '';

  static Future<String> pagesToImages(String path, String format) async =>
      await _pdf.invokeMethod<String>('pagesToImages', {
        'path': path,
        'format': format,
      }) ?? '';

  static Future<({Uint8List bytes, int width, int height})> renderPage(String path, int index) async {
    final data = await _pdf.invokeMapMethod<String, dynamic>('renderPage', {'path': path, 'index': index});
    if (data == null || data['bytes'] is! Uint8List) throw const FormatException('Page image unavailable.');
    return (bytes: data['bytes'] as Uint8List, width: data['width'] as int, height: data['height'] as int);
  }

  static Future<Map<String, List<Map<String, dynamic>>>> readAnnotations(String statePath) async {
    final raw = await _pdf.invokeMethod<String>('getEditState', {'path': statePath}) ?? '{}';
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['annotations'] is! Map) return {};
    return {
      for (final entry in (decoded['annotations'] as Map).entries)
        if (entry.key is String && entry.value is List)
          entry.key as String: [
            for (final value in entry.value as List)
              if (value is Map) Map<String, dynamic>.from(value),
          ],
    };
  }

  static Future<void> writeAnnotations(String statePath, Map<String, List<Map<String, dynamic>>> pages) async {
    await _pdf.invokeMethod<bool>('setEditState', {
      'path': statePath,
      'json': jsonEncode({'annotations': pages}),
    });
  }
}
