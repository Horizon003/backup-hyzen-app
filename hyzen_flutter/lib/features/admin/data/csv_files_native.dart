import 'package:flutter/services.dart';
import '../domain/import_formats.dart';

class SelectedCsv {
  const SelectedCsv(this.name, this.text);
  final String name, text;
}

const _channel = MethodChannel('com.hyzen.pharmd/csv_files');
Future<List<SelectedCsv>> pickCsvFiles() async {
  final result = await _channel.invokeMethod<List<dynamic>>('pickDataFiles');
  return [
    for (final entry in result ?? const [])
      SelectedCsv(
        entry['name'] as String,
        dataFileCsv(entry['name'] as String, entry['bytes'] as Uint8List),
      ),
  ];
}

Future<bool> saveCsvTemplate(String text) async =>
    await _channel.invokeMethod<bool>('saveCsvTemplate', {'text': text}) ??
    false;
