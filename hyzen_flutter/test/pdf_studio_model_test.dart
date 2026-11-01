import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/studio_file_item.dart';

void main() {
  test('PDF Studio history round-trips workspace metadata', () {
    final created = DateTime.utc(2026, 10, 15, 10, 30);
    final opened = DateTime.utc(2026, 10, 15, 11, 15);
    final original = StudioFileItem(
      id: 'file-1',
      originalFileName: 'lecture.pdf',
      displayName: 'Lecture final.pdf',
      internalFilePath: '/private/pdf_studio/workspace/file-1.pdf',
      editStateJsonPath: '/private/pdf_studio/state/file-1_state.json',
      sourceType: 'EXTERNAL_INTENT',
      fileCategory: 'PDF',
      fileSizeBytes: 4096,
      pageCount: 12,
      isStarred: true,
      createdAt: created,
      updatedAt: created,
      lastOpenedPage: 4,
      lastOpenedAt: opened,
      operationBadge: 'IMPORTED',
    );

    final restored = StudioFileItem.fromMap(original.toMap());

    expect(restored, isNotNull);
    expect(restored!.displayName, original.displayName);
    expect(restored.fileSizeBytes, 4096);
    expect(restored.pageCount, 12);
    expect(restored.isStarred, isTrue);
    expect(restored.lastOpenedPage, 4);
    expect(restored.lastOpenedAt, opened);
    expect(StudioFileItem.fromMap({'id': 'missing-path'}), isNull);
  });
}
