import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/media_upload.dart';
import '../../../core/widgets/common.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_file_item.dart';
import '../data/studio_pdf_engine.dart';
import '../data/studio_text_export.dart';
import '../../search/data/ocr_index.dart';

enum _Format {
  original,
  flat,
  layered,
  protected,
  compressed,
  ocrPdf,
  ocrText,
  text,
  md,
  docx,
  png,
  jpg,
}

enum _Destination { studio, device, share }

Future<void> showStudioExportSheet(
  BuildContext context,
  StudioFileItem file,
) async {
  final pdf = file.internalFilePath.toLowerCase().endsWith('.pdf');
  final notes = pdf
      ? await StudioPdfEngine.readAnnotations(file.editStateJsonPath)
      : <String, List<Map<String, dynamic>>>{};
  if (!context.mounted) return;
  final marks = notes.values.any((p) => p.isNotEmpty);
  final options = <(_Format, IconData, String)>[
    (
      _Format.original,
      Icons.file_present,
      pdf ? 'Original PDF' : 'Original file',
    ),
    if (pdf) ...[
      if (marks) ...[
        (
          _Format.layered,
          Icons.layers_outlined,
          'PDF with editable annotations',
        ),
        (_Format.flat, Icons.draw_rounded, 'Flattened PDF copy'),
      ],
      (_Format.protected, Icons.lock_outline, 'Password-protected PDF'),
      (_Format.compressed, Icons.compress_rounded, 'Smaller PDF'),
      (
        _Format.ocrPdf,
        Icons.document_scanner_outlined,
        'Make scanned PDF searchable · OCR',
      ),
      (
        _Format.ocrText,
        Icons.text_fields_rounded,
        'Recognize scanned text · OCR',
      ),
      (_Format.text, Icons.text_snippet_outlined, 'Extract text · TXT'),
      (_Format.md, Icons.notes_rounded, 'Extract text · Markdown'),
      (_Format.docx, Icons.description_outlined, 'Text document · DOCX'),
      (_Format.png, Icons.image_outlined, 'PNG pages · ZIP'),
      (_Format.jpg, Icons.photo_library_outlined, 'JPG pages · ZIP'),
    ],
  ];
  final format = await showModalBottomSheet<_Format>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .75,
        child: ListView(
          children: [
            const ListTile(title: Text('Export document')),
            for (final option in options)
              ListTile(
                leading: Icon(option.$2),
                title: Text(option.$3),
                onTap: () => Navigator.pop(sheet, option.$1),
              ),
          ],
        ),
      ),
    ),
  );
  if (format == null || !context.mounted) return;
  String? password;
  var preset = 'balanced';
  if (format == _Format.protected) {
    password = await _password(context);
    if (password == null || !context.mounted) return;
  }
  if (format == _Format.compressed) {
    final chosen = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('PDF size'),
        children: [
          for (final choice in [
            ('small', 'Smallest file'),
            ('balanced', 'Balanced'),
            ('quality', 'Higher quality'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, choice.$1),
              child: Text(choice.$2),
            ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;
    preset = chosen;
  }
  final destination = await showModalBottomSheet<_Destination>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Save your copy')),
          for (final choice in [
            if (format != _Format.png && format != _Format.jpg)
              (_Destination.studio, Icons.folder_outlined, 'Office Workspace'),
            (_Destination.device, Icons.save_alt, 'Save As on device'),
            (_Destination.share, Icons.share, 'Share with an app'),
          ])
            ListTile(
              leading: Icon(choice.$2),
              title: Text(choice.$3),
              onTap: () => Navigator.pop(sheet, choice.$1),
            ),
        ],
      ),
    ),
  );
  if (destination == null || !context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  final container = ProviderScope.containerOf(context, listen: false);
  var processing = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                format == _Format.ocrPdf || format == _Format.ocrText
                    ? 'Recognizing text on this device…'
                    : 'Preparing your copy…',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    var path = file.internalFilePath;
    var name = file.displayName;
    var mime = pdf ? 'application/pdf' : 'application/octet-stream';
    final stem = name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    if (format == _Format.layered || format == _Format.flat) {
      final count = await StudioPdfEngine.pageCount(path);
      path = await StudioPdfEngine.compose([
        for (var i = 0; i < count; i++)
          StudioPage(
            file.internalFilePath,
            i,
            annotations: notes['${i + 1}'] ?? const [],
          ),
      ], flatten: format == _Format.flat);
      name = '${stem}_${format == _Format.flat ? 'flat' : 'annotated'}.pdf';
    } else if (format == _Format.protected) {
      path = await StudioPdfEngine.protect(path, password!);
      name = '${stem}_protected.pdf';
    } else if (format == _Format.compressed) {
      path = await StudioPdfEngine.compress(path, preset);
      name = '${stem}_optimized.pdf';
    } else if (format == _Format.ocrPdf || format == _Format.ocrText) {
      final result = await StudioPdfEngine.ocr(path);
      if (result.text.trim().isEmpty) {
        throw const FormatException('No readable Latin text was found.');
      }
      await container
          .read(ocrIndexProvider.notifier)
          .save(
            documentId: file.id,
            documentName: file.displayName,
            pages: result.pages.isEmpty ? [result.text] : result.pages,
          );
      path = format == _Format.ocrPdf
          ? result.path
          : await StudioPdfEngine.textFile(result.text);
      name = '${stem}_ocr.${format == _Format.ocrPdf ? 'pdf' : 'txt'}';
      mime = format == _Format.ocrPdf ? 'application/pdf' : 'text/plain';
    } else if (format == _Format.text ||
        format == _Format.md ||
        format == _Format.docx) {
      final text = await extractStudioPdfText(path);
      if (text.trim().isEmpty) {
        throw const FormatException('Use OCR for scanned pages.');
      }
      path = format == _Format.docx
          ? await StudioPdfEngine.textToDocx(text)
          : await StudioPdfEngine.textFile(text);
      name =
          '$stem.${format == _Format.docx
              ? 'docx'
              : format == _Format.md
              ? 'md'
              : 'txt'}';
      mime = format == _Format.docx
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : format == _Format.md
          ? 'text/markdown'
          : 'text/plain';
    } else if (format == _Format.png || format == _Format.jpg) {
      path = await StudioPdfEngine.pagesToImages(
        path,
        format == _Format.png ? 'png' : 'jpg',
      );
      name = '${stem}_pages.zip';
      mime = 'application/zip';
    }
    if (processing && navigator.mounted) {
      navigator.pop();
      processing = false;
    }
    if (!context.mounted) return;
    if (destination == _Destination.studio) {
      await ProviderScope.containerOf(context, listen: false)
          .read(pdfStudioHistoryProvider.notifier)
          .importFile(
            path,
            originalFileName: name,
            sourceType: 'CREATED',
            operationBadge: 'EXPORTED',
          );
      if (context.mounted) showHSnack(context, 'Saved in Office Workspace');
    } else {
      final ok = destination == _Destination.device
          ? await MediaUpload.exportDocument(path, name, mime)
          : await MediaUpload.shareDocument(path, name, mime);
      if (context.mounted) {
        showHSnack(context, ok ? 'Copy ready' : 'Export cancelled');
      }
    }
  } catch (error) {
    if (processing && navigator.mounted) {
      navigator.pop();
      processing = false;
    }
    if (context.mounted) {
      showHSnack(
        context,
        error is FormatException
            ? error.message
            : 'Could not export this document. Try a different option.',
        error: true,
      );
    }
  } finally {
    password = null;
    if (processing && navigator.mounted) navigator.pop();
  }
}

Future<String?> _password(BuildContext context) async {
  final password = TextEditingController();
  final confirm = TextEditingController();
  final key = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Protect this PDF'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) => (v?.length ?? 0) < 6
                  ? 'Use at least 6 characters'
                  : (v?.length ?? 0) > 128
                  ? 'Use up to 128 characters'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirm,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (v) =>
                  v != password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 12),
            const Text('Keep your password safe. It cannot be recovered.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(c, password.text);
          },
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  password.dispose();
  confirm.dispose();
  return result;
}
