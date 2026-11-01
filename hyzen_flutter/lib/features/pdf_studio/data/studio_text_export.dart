import 'package:pdfrx/pdfrx.dart';

/// Extracts selectable PDF text. Image-only pages need OCR and return blank.
Future<String> extractStudioPdfText(String path) async {
  final document = await PdfDocument.openFile(path);
  try {
    final buffer = StringBuffer();
    for (var index = 0; index < document.pages.length; index++) {
      final text = await document.pages[index].loadText();
      if (index > 0) buffer.writeln('\n\n--- Page ${index + 1} ---\n');
      buffer.write(text.fullText);
    }
    return buffer.toString();
  } finally {
    await document.dispose();
  }
}
