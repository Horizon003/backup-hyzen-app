import 'download_record.dart';

/// Select the renderer using bytes, never a title or Drive's misleading MIME.
String? documentExtension(List<int> bytes) {
  if (bytes.length >= 8 &&
      bytes.take(8).join(',') == '208,207,17,224,161,177,26,225') {
    return 'legacy';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'webp';
  }
  if (PdfSniffer.isPdf(bytes)) return 'pdf';
  if (bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4b &&
      bytes[2] == 3 &&
      bytes[3] == 4) {
    return 'office';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return 'jpg';
  }
  return null;
}
