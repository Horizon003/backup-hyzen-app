import '../../academics/domain/models.dart';

enum DownloadStatus { downloading, paused, ready, failed }

/// Typed local metadata for one offline document (Hive `downloads_v1`).
/// Key = legacy offline key (`drive_{id}` | `url_{hash}`) → prevents duplicates.
class DownloadRecord {
  DownloadRecord({
    required this.key,
    required this.kind,
    required this.title,
    required this.sourceUrl,
    required this.status,
    this.localPath,
    this.sizeBytes = 0,
    this.progress = 0,
    this.savedAt,
    this.trail = const [],
    this.error,
    this.totalBytes,
    this.startedAt,
    this.unopened = false,
    this.firstOpenedAt,
    this.availabilityVerified = true,
  });

  final bool unopened;
  final DateTime? firstOpenedAt;
  /// Runtime verification is deliberately not trusted from persisted metadata.
  final bool availabilityVerified;
  bool get isAvailableOffline => isReady && availabilityVerified;

  final String key;
  final LibraryKind kind;
  final String title;
  final String sourceUrl;
  final DownloadStatus status;
  final String? localPath;
  final int sizeBytes;
  final double progress;
  final DateTime? savedAt;

  /// Hierarchy labels: [year, semester, subject, section, topic].
  final List<String> trail;
  final String? error;
  final int? totalBytes;
  final DateTime? startedAt;
  String get transferDetail {
    final elapsed = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt!).inSeconds;
    final bytes = totalBytes == null
        ? formatBytes(sizeBytes)
        : '${formatBytes(sizeBytes)} / ${formatBytes(totalBytes!)}';
    if (elapsed < 2 || sizeBytes == 0) return '$bytes · Connecting…';
    if (totalBytes == null) return '$bytes · ${elapsed}s elapsed';
    final remaining = ((totalBytes! - sizeBytes) / (sizeBytes / elapsed))
        .ceil()
        .clamp(0, 86400);
    return '$bytes · about ${remaining < 60 ? '${remaining}s' : '${(remaining / 60).ceil()} min'} left';
  }

  bool get isReady => status == DownloadStatus.ready && localPath != null;

  String get subtitle => trail.where((e) => e.isNotEmpty).join(' · ');

  Map<String, dynamic> toMap() => {
    'key': key,
    'kind': kind.name,
    'title': title,
    'sourceUrl': sourceUrl,
    'status': status.name,
    'localPath': localPath,
    'sizeBytes': sizeBytes,
    'progress': progress,
    'savedAt': savedAt?.toIso8601String(),
    'trail': trail,
    'error': error,
    'totalBytes': totalBytes,
    'startedAt': startedAt?.toIso8601String(),
    'unopened': unopened,
    'firstOpenedAt': firstOpenedAt?.toIso8601String(),
  };

  static DownloadRecord? fromMap(Map<String, dynamic> m) {
    final key = m['key'];
    if (key is! String) return null;
    return DownloadRecord(
      key: key,
      kind: LibraryKindX.parse(m['kind'] as String?) ?? LibraryKind.notes,
      title: (m['title'] as String?) ?? 'Document',
      sourceUrl: (m['sourceUrl'] as String?) ?? '',
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => DownloadStatus.failed,
      ),
      localPath: m['localPath'] as String?,
      sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
      progress: (m['progress'] as num?)?.toDouble() ?? 0,
      savedAt: DateTime.tryParse('${m['savedAt']}'),
      trail: (m['trail'] is List)
          ? (m['trail'] as List).map((e) => '$e').toList()
          : const [],
      error: m['error'] as String?,
      totalBytes: (m['totalBytes'] as num?)?.toInt(),
      startedAt: DateTime.tryParse('${m['startedAt']}'),
      unopened: m['unopened'] == true,
      firstOpenedAt: DateTime.tryParse('${m['firstOpenedAt']}'),
      availabilityVerified: false,
    );
  }

  DownloadRecord copyWith({
    DownloadStatus? status,
    String? localPath,
    int? sizeBytes,
    double? progress,
    DateTime? savedAt,
    String? error,
    int? totalBytes,
    DateTime? startedAt,
    bool? unopened,
    DateTime? firstOpenedAt,
    bool? availabilityVerified,
  }) => DownloadRecord(
    key: key,
    kind: kind,
    title: title,
    sourceUrl: sourceUrl,
    status: status ?? this.status,
    localPath: localPath ?? this.localPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    progress: progress ?? this.progress,
    savedAt: savedAt ?? this.savedAt,
    trail: trail,
    error: error,
    totalBytes: totalBytes ?? this.totalBytes,
    startedAt: startedAt ?? this.startedAt,
    unopened: unopened ?? this.unopened,
    firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
    availabilityVerified: availabilityVerified ?? this.availabilityVerified,
  );
}

/// What the viewer needs to open / save a file.
class FileRef {
  const FileRef({
    required this.kind,
    required this.title,
    required this.url,
    this.trail = const [],
  });
  final LibraryKind kind;
  final String title;
  final String url;
  final List<String> trail;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'title': title,
    'url': url,
    'trail': trail,
  };
  static FileRef? fromMap(Map<String, dynamic> m) {
    final url = m['url'];
    if (url is! String) return null;
    return FileRef(
      kind: LibraryKindX.parse(m['kind'] as String?) ?? LibraryKind.notes,
      title: (m['title'] as String?) ?? 'Document',
      url: url,
      trail: (m['trail'] is List)
          ? (m['trail'] as List).map((e) => '$e').toList()
          : const [],
    );
  }
}

/// Validates downloaded bytes: must start with `%PDF-`; HTML/login/quota pages rejected.
class PdfSniffer {
  PdfSniffer._();
  static bool isPdf(List<int> head) =>
      head.length >= 5 &&
      head[0] == 0x25 &&
      head[1] == 0x50 &&
      head[2] == 0x44 &&
      head[3] == 0x46 &&
      head[4] == 0x2D;

  static bool looksLikeHtml(List<int> head) {
    final s = String.fromCharCodes(head.take(512)).toLowerCase().trimLeft();
    return s.startsWith('<!doctype') ||
        s.startsWith('<html') ||
        s.contains('<head') ||
        s.contains('<body');
  }
}

String formatBytes(int b) {
  if (b <= 0) return '0 B';
  const u = ['B', 'KB', 'MB', 'GB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${u[i]}';
}
