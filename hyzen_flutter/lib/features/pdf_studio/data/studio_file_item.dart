class StudioFileItem {
  const StudioFileItem({
    required this.id,
    required this.originalFileName,
    required this.displayName,
    required this.internalFilePath,
    required this.editStateJsonPath,
    required this.sourceType,
    required this.fileCategory,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.pageCount = 0,
    this.isStarred = false,
    this.lastOpenedPage = 1,
    this.lastOpenedAt,
    this.operationBadge = 'IMPORTED',
  });

  final String id;
  final String originalFileName;
  final String displayName;
  final String internalFilePath;
  final String editStateJsonPath;
  final String? thumbnailPath;
  final String sourceType;
  final String fileCategory;
  final int fileSizeBytes;
  final int pageCount;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int lastOpenedPage;
  final DateTime? lastOpenedAt;
  final String operationBadge;

  StudioFileItem copyWith({
    String? displayName,
    int? pageCount,
    bool? isStarred,
    DateTime? updatedAt,
    int? lastOpenedPage,
    DateTime? lastOpenedAt,
    String? operationBadge,
  }) =>
      StudioFileItem(
        id: id,
        originalFileName: originalFileName,
        displayName: displayName ?? this.displayName,
        internalFilePath: internalFilePath,
        editStateJsonPath: editStateJsonPath,
        thumbnailPath: thumbnailPath,
        sourceType: sourceType,
        fileCategory: fileCategory,
        fileSizeBytes: fileSizeBytes,
        pageCount: pageCount ?? this.pageCount,
        isStarred: isStarred ?? this.isStarred,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastOpenedPage: lastOpenedPage ?? this.lastOpenedPage,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        operationBadge: operationBadge ?? this.operationBadge,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'original_file_name': originalFileName,
    'display_name': displayName,
    'internal_file_path': internalFilePath,
    'edit_state_json_path': editStateJsonPath,
    'thumbnail_path': thumbnailPath,
    'source_type': sourceType,
    'file_category': fileCategory,
    'file_size_bytes': fileSizeBytes,
    'page_count': pageCount,
    'is_starred': isStarred,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'last_opened_page': lastOpenedPage,
    'last_opened_at': lastOpenedAt?.toIso8601String(),
    'operation_badge': operationBadge,
  };

  static StudioFileItem? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final path = map['internal_file_path'];
    final created = DateTime.tryParse('${map['created_at']}');
    final updated = DateTime.tryParse('${map['updated_at']}');
    if (id is! String || path is! String || created == null || updated == null) {
      return null;
    }
    return StudioFileItem(
      id: id,
      originalFileName: map['original_file_name'] as String? ?? 'Document',
      displayName: map['display_name'] as String? ?? 'Document',
      internalFilePath: path,
      editStateJsonPath: map['edit_state_json_path'] as String? ?? '',
      thumbnailPath: map['thumbnail_path'] as String?,
      sourceType: map['source_type'] as String? ?? 'INTERNAL',
      fileCategory: map['file_category'] as String? ?? 'PDF',
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      pageCount: (map['page_count'] as num?)?.toInt() ?? 0,
      isStarred: map['is_starred'] == true,
      createdAt: created,
      updatedAt: updated,
      lastOpenedPage: (map['last_opened_page'] as num?)?.toInt() ?? 1,
      lastOpenedAt: DateTime.tryParse('${map['last_opened_at']}'),
      operationBadge: map['operation_badge'] as String? ?? 'IMPORTED',
    );
  }
}
