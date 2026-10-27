import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'legacy_ppt.dart';

/// Bounded, offline reading view of Office Open XML documents. Not a replacement
/// for PowerPoint's exact typography/animations. No network or script execution.
List<String> officePages(Uint8List bytes) {
  if (bytes.length >= 8 && bytes[0] == 208 && bytes[1] == 207) {
    return legacyPptPages(bytes);
  }
  if (bytes.length > 50 * 1024 * 1024) {
    throw const FormatException(
      'Office notes over 50 MB: please provide a PDF copy.',
    );
  }
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  if (archive.files.length > 3000 ||
      archive.files.fold<int>(0, (n, f) => n + f.size) > 100 * 1024 * 1024) {
    throw const FormatException(
      'This Office document is too complex. Use its PDF copy.',
    );
  }
  final slides =
      archive.files
          .where((f) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name))
          .toList()
        ..sort(
          (a, b) => int.parse(
            RegExp(r'\d+').firstMatch(a.name)!.group(0)!,
          ).compareTo(int.parse(RegExp(r'\d+').firstMatch(b.name)!.group(0)!)),
        );
  String text(ArchiveFile f, String local) {
    if (f.size > 5 * 1024 * 1024) {
      throw const FormatException('Document page too large.');
    }
    final xml = XmlDocument.parse(utf8.decode(f.content as List<int>));
    return xml.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == local)
        .map(
          (e) => e.descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 't')
              .map((e) => e.innerText)
              .join(' '),
        )
        .where((s) => s.trim().isNotEmpty)
        .join('\n\n');
  }

  if (slides.isNotEmpty) return slides.map((f) => text(f, 'p')).toList();
  final doc = archive.findFile('word/document.xml');
  if (doc != null) return [text(doc, 'p')];
  // Spreadsheet shared strings and worksheet values are rendered read-only.
  final shared = archive.findFile('xl/sharedStrings.xml');
  final strings = shared == null
      ? <String>[]
      : XmlDocument.parse(
          utf8.decode(shared.content as List<int>),
        ).findAllElements('si').map((e) => e.innerText).toList();
  final sheets = archive.files.where(
    (f) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name),
  );
  if (sheets.isNotEmpty) {
    return sheets.map((f) {
      final xml = XmlDocument.parse(utf8.decode(f.content as List<int>));
      return xml
          .findAllElements('row')
          .map(
            (r) => r
                .findElements('c')
                .map((c) {
                  final value =
                      c.getElement('v')?.innerText ??
                      c.getElement('is')?.innerText ??
                      '';
                  final n = int.tryParse(value);
                  return c.getAttribute('t') == 's' &&
                          n != null &&
                          n >= 0 &&
                          n < strings.length
                      ? strings[n]
                      : value;
                })
                .join('  |  '),
          )
          .join('\n\n');
    }).toList();
  }
  throw const FormatException(
    'Not a supported PPTX, DOCX or XLSX file. Ask for a PDF copy.',
  );
}
