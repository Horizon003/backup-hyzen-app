import 'dart:async';
import 'dart:js_interop';
import '../domain/import_formats.dart';
import 'package:web/web.dart' as web;

class SelectedCsv {
  const SelectedCsv(this.name, this.text);
  final String name, text;
}

Future<List<SelectedCsv>> pickCsvFiles() {
  final result = Completer<List<SelectedCsv>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.csv,.json,.xlsx'
    ..multiple = true;
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!result.isCompleted) result.complete([]);
    }).toJS,
  );
  input.addEventListener(
    'change',
    ((web.Event _) {
      () async {
        try {
          final files = input.files;
          final selected = <SelectedCsv>[];
          if ((files?.length ?? 0) > 20) {
            throw StateError('Choose at most 20 CSV files.');
          }
          for (var i = 0; i < (files?.length ?? 0); i++) {
            final file = files!.item(i)!;
            if (file.size > 4 * 1024 * 1024) {
              throw StateError('Each CSV must be 4 MB or smaller.');
            }
            final buffer = await file.arrayBuffer().toDart;
            selected.add(
              SelectedCsv(
                file.name,
                dataFileCsv(file.name, buffer.toDart.asUint8List()),
              ),
            );
          }
          if (!result.isCompleted) result.complete(selected);
        } catch (e, st) {
          if (!result.isCompleted) result.completeError(e, st);
        }
      }();
    }).toJS,
  );
  input.click();
  return result.future;
}

Future<bool> saveCsvTemplate(String text) async {
  final uri = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(text)}';
  final link = web.HTMLAnchorElement()
    ..href = uri
    ..download = 'hyzen_bulk_import_template.csv';
  link.click();
  return true;
}
