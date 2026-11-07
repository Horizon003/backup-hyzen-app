import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/study_progress/study_tracker.dart';

void main() {
  test('study streak uses today or yesterday, not imaginary future days', () {
    final days = <String, int>{
      '2026-11-03': 70,
      '2026-11-04': 75,
      '2026-11-05': 65,
      '2026-11-07': 90,
    };
    expect(StudyStats.streak(days, DateTime(2026, 11, 7)), 1);
    expect(StudyStats.streak(days, DateTime(2026, 11, 6)), 3);
    expect(StudyStats.bestStreak(days), 3);
    expect(StudyStats.recentBreaks(days), isNotEmpty);
  });

  test('calendar week starts on Monday and goal is based on real seconds', () {
    final days = <String, int>{
      '2026-11-01': 600,
      '2026-11-02': 120,
      '2026-11-07': 180,
      '2026-11-08': 60,
      '2026-11-09': 400,
    };
    expect(StudyStats.weekSeconds(days, DateTime(2026, 11, 7)), 360);
    expect(StudyStats.weekSeconds(days, DateTime(2026, 11, 9)), 400);
  });

  test('only at least 60 seconds earns a streak day', () {
    expect(StudyStats.streak({'2026-11-07': 59}, DateTime(2026, 11, 7)), 0);
    expect(StudyStats.streak({'2026-11-07': 60}, DateTime(2026, 11, 7)), 1);
  });

  test('task reminder state round-trips without changing the due time', () {
    final due = DateTime(2026, 11, 23, 9, 30);
    final item = StudyTask('1', 'Pharmacology', due: due);
    final restored = StudyTask.fromJson(item.toJson());
    expect(restored.due, due);
    expect(restored.done, false);
    expect(restored.change(done: true).done, true);
  });
}
