/// Google Drive / Google Docs link helpers.
///
/// CONFIRMED (legacy v2 `driveFileId`, `filePreviewUrl`, `fileDownloadUrl`,
/// offline-key scheme in the offline library). Ported 1:1 so the same Firestore
/// `pdfUrl` values behave identically in the app.
class DriveLinks {
  DriveLinks._();

  static final _reFile = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
  static final _reId = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
  static final _reD = RegExp(r'/d/([a-zA-Z0-9_-]+)');

  /// Same regex order as legacy: /file/d/ → ?id= → /d/.
  static String fileId(String? url) {
    final u = (url ?? '').trim();
    final uri = Uri.tryParse(u);
    if (uri == null ||
        !{
          'drive.google.com',
          'docs.google.com',
          'drive.usercontent.google.com',
        }.contains(uri.host)) {
      return '';
    }
    for (final re in [_reFile, _reId, _reD]) {
      final m = re.firstMatch(u);
      if (m != null) return m.group(1)!;
    }
    return '';
  }

  /// CONFIRMED legacy preview URL (used for every Drive/Docs id).
  static String previewUrl(String? url) {
    final id = fileId(url);
    if (id.isNotEmpty) {
      final e = Uri.encodeComponent(id);
      if (kindOf(url) == DocKind.slides) {
        return 'https://docs.google.com/presentation/d/$e/preview';
      }
      if (kindOf(url) == DocKind.document) {
        return 'https://docs.google.com/document/d/$e/preview';
      }
      if (kindOf(url) == DocKind.sheet) {
        return 'https://docs.google.com/spreadsheets/d/$e/preview';
      }
      final key = Uri.tryParse(url ?? '')?.queryParameters['resourcekey'];
      return 'https://drive.google.com/file/d/$e/preview${key == null ? '' : '?resourcekey=${Uri.encodeComponent(key)}'}';
    }
    return (url ?? '').trim();
  }

  static DocKind kindOf(String? url) {
    final u = (url ?? '').toLowerCase();
    if (Uri.tryParse(u)?.host == 'docs.google.com' &&
        u.contains('/presentation/')) {
      return DocKind.slides;
    }
    if (Uri.tryParse(u)?.host == 'docs.google.com' &&
        u.contains('/document/')) {
      return DocKind.document;
    }
    if (Uri.tryParse(u)?.host == 'docs.google.com' &&
        u.contains('/spreadsheets/')) {
      return DocKind.sheet;
    }
    if (fileId(url).isNotEmpty) return DocKind.driveFile;
    return DocKind.other;
  }

  /// Raw bytes URL for Save Offline (app only).
  /// - Drive files: CONFIRMED legacy direct URL (drive.usercontent … confirm=t).
  /// - Google Slides/Docs/Sheets: NEW — Google's public PDF export endpoints
  ///   (works only when the file is shared "anyone with the link").
  static String downloadUrl(String? url, {String? title}) {
    final id = fileId(url);
    final e = Uri.encodeComponent(id);
    final ext = (title ?? '').trim().toLowerCase().split('.').last;
    if (kindOf(url) == DocKind.driveFile && id.isNotEmpty) {
      if ({'ppt', 'pptx', 'pptm'}.contains(ext)) {
        return _resourceKey(
          'https://docs.google.com/presentation/d/$e/export/pdf',
          url,
        );
      }
      if ({'doc', 'docx'}.contains(ext)) {
        return _resourceKey(
          'https://docs.google.com/document/d/$e/export?format=pdf',
          url,
        );
      }
      if ({'xls', 'xlsx'}.contains(ext)) {
        return _resourceKey(
          'https://docs.google.com/spreadsheets/d/$e/export?format=pdf',
          url,
        );
      }
    }
    switch (kindOf(url)) {
      case DocKind.slides:
        return _resourceKey(
          'https://docs.google.com/presentation/d/$e/export/pdf',
          url,
        );
      case DocKind.document:
        return _resourceKey(
          'https://docs.google.com/document/d/$e/export?format=pdf',
          url,
        );
      case DocKind.sheet:
        return _resourceKey(
          'https://docs.google.com/spreadsheets/d/$e/export?format=pdf',
          url,
        );
      case DocKind.driveFile:
        final key = Uri.tryParse(url ?? '')?.queryParameters['resourcekey'];
        return 'https://drive.usercontent.google.com/download?id=$e&export=download&confirm=t${key == null ? '' : '&resourcekey=${Uri.encodeComponent(key)}'}';
      case DocKind.other:
        return (url ?? '').trim();
    }
  }

  /// CONFIRMED legacy offline key: `drive_{id}` or `url_{fnv1a36}`.
  static String _resourceKey(String target, String? source) {
    final key = Uri.tryParse(source ?? '')?.queryParameters['resourcekey'];
    if (key == null) return target;
    final uri = Uri.parse(target);
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'resourcekey': key})
        .toString();
  }

  static String offlineKey(String? url) {
    final id = fileId(url);
    if (id.isNotEmpty) return 'drive_$id';
    return 'url_${fnv1a36((url ?? '').trim())}';
  }

  /// FNV-1a 32-bit over UTF-16 code units, base-36 — identical to legacy JS
  /// (h=2166136261; h^=charCode; h=Math.imul(h,16777619); (h>>>0).toString(36)).
  static String fnv1a36(String s) {
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h ^= c;
      // 16777619 = 0x01000193 → h*403 + (h<<24); split keeps web (JS) precision exact.
      h = (h * 403 + ((h << 24) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    }
    return h.toRadixString(36);
  }
}

enum DocKind { driveFile, slides, document, sheet, other }
