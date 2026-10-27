import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../academics/domain/drive.dart';
import '../../downloads/domain/download_record.dart';

/// Device-local "Continue studying" history (real data only — files the student opened).
class RecentItem {
  RecentItem(this.file, this.openedAt);
  final FileRef file;
  final DateTime openedAt;
}

class RecentController extends Notifier<List<RecentItem>> {
  static const max = 20;
  JsonBox get _box => JsonBox(Boxes.recent);

  @override
  List<RecentItem> build() {
    final items = <RecentItem>[];
    for (final m in JsonBox(Boxes.recent).values()) {
      final f = FileRef.fromMap(m);
      final t = DateTime.tryParse('${m['openedAt']}');
      if (f != null && t != null) items.add(RecentItem(f, t));
    }
    items.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return items;
  }

  Future<void> touch(FileRef f) async {
    final key = DriveLinks.offlineKey(f.url);
    final now = DateTime.now();
    await _box.put(key, {...f.toMap(), 'openedAt': now.toIso8601String()});
    final next = [
      RecentItem(f, now),
      ...state.where((r) => DriveLinks.offlineKey(r.file.url) != key),
    ];
    if (next.length > max) {
      for (final r in next.sublist(max)) {
        await _box.delete(DriveLinks.offlineKey(r.file.url));
      }
    }
    state = next.take(max).toList();
  }

  Future<void> clear() async {
    await _box.clear();
    state = [];
  }
}

final recentProvider = NotifierProvider<RecentController, List<RecentItem>>(
  RecentController.new,
);
