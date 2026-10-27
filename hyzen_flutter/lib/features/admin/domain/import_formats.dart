import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../../../core/errors/app_error.dart';
import 'import_csv.dart';

String csvCell(Object? value) => '"${'${value ?? ''}'.replaceAll('"', '""')}"';
String tableCsv(List<List<Object?>> rows) =>
    rows.map((r) => r.map(csvCell).join(',')).join('\r\n');
String dataFileCsv(String name, Uint8List bytes) {
  final ext = name.toLowerCase().split('.').last;
  if (ext == 'csv') return utf8.decode(bytes);
  if (ext == 'json') {
    final decoded = jsonDecode(utf8.decode(bytes));
    final rows = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['rows']
        : null;
    if (rows is! List || rows.isEmpty || rows.any((r) => r is! Map)) {
      throw FriendlyException(
        'Import JSON should be an array of resource rows or an object with a rows array. Use Data Manager for a full backup.',
      );
    }
    final maps = rows.cast<Map>();
    final headers = <String>{
      for (final row in maps) ...row.keys.map((k) => '$k'),
    }.toList();
    return tableCsv([
      headers,
      for (final row in maps) [for (final key in headers) row[key]],
    ]);
  }
  if (ext != 'xlsx') {
    throw FriendlyException(
      'Choose CSV, JSON or XLSX. Save older XLS files as CSV first.',
    );
  }
  final zip = ZipDecoder().decodeBytes(bytes, verify: true);
  var total = 0;
  for (final f in zip) {
    total += f.size;
    if (total > 32 * 1024 * 1024) {
      throw FriendlyException('Workbook is too large after decompression.');
    }
  }
  XmlDocument? document(String path) {
    final files = zip.files.where((f) => f.name == path);
    if (files.isEmpty) return null;
    return XmlDocument.parse(utf8.decode(files.first.content as List<int>));
  }

  final shared = <String>[];
  for (final si
      in document('xl/sharedStrings.xml')?.findAllElements('si') ??
          <XmlElement>[]) {
    shared.add(si.findAllElements('t').map((t) => t.innerText).join());
  }
  final sheet =
      zip.files
          .where(
            (f) => RegExp(r'^xl/worksheets/sheet[0-9]+\.xml$').hasMatch(f.name),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  if (sheet.isEmpty) {
    throw FriendlyException('Workbook has no readable worksheets.');
  }
  final result = <List<Object?>>[];
  for (final file in sheet) {
    final rows = <List<Object?>>[];
    final doc = document(file.name)!;
    for (final row in doc.findAllElements('row')) {
      final columns = <int, String>{};
      for (final cell in row.findElements('c')) {
        final letters =
            RegExp(
              r'^[A-Z]+',
            ).firstMatch(cell.getAttribute('r') ?? '')?.group(0) ??
            'A';
        var column = 0;
        for (final unit in letters.codeUnits) {
          column = column * 26 + unit - 64;
        }
        column--;
        if (column > 80) {
          throw FriendlyException('Workbook has too many columns.');
        }
        final raw = cell.getElement('v')?.innerText ?? '';
        final type = cell.getAttribute('t');
        final value = type == 's'
            ? (int.tryParse(raw) != null && int.parse(raw) < shared.length
                  ? shared[int.parse(raw)]
                  : '')
            : type == 'inlineStr'
            ? cell.findAllElements('t').map((e) => e.innerText).join()
            : raw;
        columns[column] = value;
      }
      if (columns.isEmpty) continue;
      final max = columns.keys.reduce((a, b) => a > b ? a : b);
      rows.add([for (var i = 0; i <= max; i++) columns[i] ?? '']);
      if (rows.length > 2001) {
        throw FriendlyException('Import at most 2,000 rows at a time.');
      }
    }
    if (rows.isEmpty) continue;
    if (result.isEmpty) {
      result.addAll(rows);
    } else {
      if (rows.first.map((v) => canonicalHeader('$v')).join('|') !=
          result.first.map((v) => canonicalHeader('$v')).join('|')) {
        throw FriendlyException(
          'All workbook sheets must use the same columns.',
        );
      }
      result.addAll(rows.skip(1));
    }
  }
  return tableCsv(result);
}
