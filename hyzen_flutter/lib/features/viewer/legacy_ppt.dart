import 'dart:typed_data';

/// Read-only text extraction from the PowerPoint stream in OLE/CFB .ppt files.
/// All sector chains are bounded and cycles rejected; macros are never executed.
List<String> legacyPptPages(Uint8List bytes) {
  if (bytes.length < 512 || bytes.length > 50 * 1024 * 1024) {
    throw const FormatException('Invalid or oversized legacy Office document.');
  }
  final h = ByteData.sublistView(bytes);
  int u16(int o) => h.getUint16(o, Endian.little);
  int u32(int o) => h.getUint32(o, Endian.little);
  final shift = u16(30);
  if (shift != 9 && shift != 12) {
    throw const FormatException('Invalid Office sectors.');
  }
  final sectorSize = 1 << shift;
  Uint8List sector(int id) {
    final start = (id + 1) * sectorSize;
    if (id >= 0xfffffff0 ||
        start < sectorSize ||
        start + sectorSize > bytes.length) {
      throw const FormatException('Office sector out of range.');
    }
    return Uint8List.sublistView(bytes, start, start + sectorSize);
  }

  List<int> words(Uint8List b) {
    final d = ByteData.sublistView(b);
    return [
      for (var i = 0; i + 4 <= b.length; i += 4) d.getUint32(i, Endian.little),
    ];
  }

  final fatIds = <int>[
    for (var i = 0; i < 109; i++)
      if (u32(76 + i * 4) < 0xfffffff0) u32(76 + i * 4),
  ];
  var difat = u32(68);
  final seenDifat = <int>{};
  for (var n = 0; n < u32(72); n++) {
    if (!seenDifat.add(difat) || n > 4096) {
      throw const FormatException('Invalid Office allocation chain.');
    }
    final w = words(sector(difat));
    fatIds.addAll(w.take(w.length - 1).where((s) => s < 0xfffffff0));
    difat = w.last;
  }
  final fat = <int>[for (final id in fatIds) ...words(sector(id))];
  Uint8List chain(
    int id,
    List<int> allocation,
    Uint8List Function(int) read, {
    int? size,
  }) {
    final out = BytesBuilder(copy: false);
    final seen = <int>{};
    while (id < 0xfffffff0) {
      if (id >= allocation.length ||
          !seen.add(id) ||
          out.length > 50 * 1024 * 1024) {
        throw const FormatException('Invalid Office stream.');
      }
      out.add(read(id));
      id = allocation[id];
    }
    final b = out.takeBytes();
    if (size != null && size > b.length) {
      throw const FormatException('Truncated Office stream.');
    }
    return size == null ? b : Uint8List.sublistView(b, 0, size);
  }

  final directory = chain(u32(48), fat, sector);
  final entries = <({String name, int start, int size, int type})>[];
  final d = ByteData.sublistView(directory);
  for (var o = 0; o + 128 <= directory.length; o += 128) {
    final length = d.getUint16(o + 64, Endian.little);
    if (length < 2 || length > 64) continue;
    final name = String.fromCharCodes([
      for (var i = 0; i < length - 2; i += 2) d.getUint16(o + i, Endian.little),
    ]);
    entries.add((
      name: name,
      start: d.getUint32(o + 116, Endian.little),
      size: d.getUint32(o + 120, Endian.little),
      type: directory[o + 66],
    ));
  }
  final matches = entries.where((e) => e.name == 'PowerPoint Document');
  if (matches.isEmpty) {
    throw const FormatException(
      'Legacy Word documents require an Office app or a PDF copy.',
    );
  }
  final e = matches.first;
  Uint8List stream;
  if (e.size < u32(56)) {
    final root = entries.firstWhere((e) => e.type == 5);
    final mini = chain(root.start, fat, sector, size: root.size);
    final miniFat = words(chain(u32(60), fat, sector));
    stream = chain(e.start, miniFat, (id) {
      final start = id * 64;
      if (start + 64 > mini.length) {
        throw const FormatException('Invalid mini stream.');
      }
      return Uint8List.sublistView(mini, start, start + 64);
    }, size: e.size);
  } else {
    stream = chain(e.start, fat, sector, size: e.size);
  }
  final s = ByteData.sublistView(stream);
  final text = <String>[];
  void records(int start, int end, int depth) {
    if (depth > 40) {
      throw const FormatException('Too many nested PowerPoint records.');
    }
    for (var o = start; o + 8 <= end;) {
      final options = s.getUint16(o, Endian.little),
          type = s.getUint16(o + 2, Endian.little),
          length = s.getUint32(o + 4, Endian.little);
      final next = o + 8 + length;
      if (next > end) break;
      if (type == 4000) {
        text.add(
          String.fromCharCodes([
            for (var p = o + 8; p + 1 < next; p += 2)
              s.getUint16(p, Endian.little),
          ]).replaceAll('\r', '\n'),
        );
      } else if (type == 4008) {
        text.add(
          String.fromCharCodes(
            stream.sublist(o + 8, next),
          ).replaceAll('\r', '\n'),
        );
      } else if ((options & 15) == 15) {
        records(o + 8, next, depth + 1);
      }
      o = next;
    }
  }

  records(0, stream.length, 0);
  if (text.every((s) => s.trim().isEmpty)) {
    throw const FormatException(
      'No readable text in this presentation. Use its original preview or a PDF copy.',
    );
  }
  return text.where((s) => s.trim().isNotEmpty).toList();
}
