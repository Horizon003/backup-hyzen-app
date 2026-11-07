import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../notifications/notifications_screen.dart';

String studyDayKey(DateTime d) =>
    d.year.toString().padLeft(4, '0') + '-' +
    d.month.toString().padLeft(2, '0') + '-' +
    d.day.toString().padLeft(2, '0');

String formatStudyTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds ~/ 60) % 60;
  final s = seconds % 60;
  return h > 0
      ? '$h h ' + m.toString().padLeft(2, '0') + ' m'
      : '$m m ' + s.toString().padLeft(2, '0') + ' s';
}

class StudyStats {
  static int weekSeconds(Map<String, int> days, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => studyDayKey(monday.add(Duration(days: i))))
        .fold(0, (sum, day) => sum + (days[day] ?? 0));
  }

  static int streak(Map<String, int> days, DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if ((days[studyDayKey(day)] ?? 0) < 60) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while ((days[studyDayKey(day)] ?? 0) >= 60) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static int bestStreak(Map<String, int> days) {
    final dates = days.keys.where((k) => (days[k] ?? 0) >= 60).toList()..sort();
    DateTime? last;
    var current = 0;
    var best = 0;
    for (final value in dates) {
      final day = DateTime.tryParse(value);
      if (day == null) continue;
      current = last != null && day.difference(last).inDays == 1
          ? current + 1 : 1;
      if (current > best) best = current;
      last = day;
    }
    return best;
  }

  static List<String> recentBreaks(Map<String, int> days) {
    final dates = days.keys.where((k) => (days[k] ?? 0) >= 60).toList()..sort();
    final breaks = <String>[];
    for (var i = dates.length - 1; i > 0 && breaks.length < 3; i--) {
      final newer = DateTime.tryParse(dates[i]);
      final older = DateTime.tryParse(dates[i - 1]);
      if (newer == null || older == null) continue;
      final skipped = newer.difference(older).inDays - 1;
      if (skipped > 0) breaks.add('$skipped missed day(s) before ' + dates[i]);
    }
    return breaks;
  }
}

class StudyTask {
  const StudyTask(this.id, this.title, {this.due, this.done = false, this.alerted = false});
  final String id;
  final String title;
  final DateTime? due;
  final bool done;
  final bool alerted;

  StudyTask change({bool? done, bool? alerted}) => StudyTask(
    id, title, due: due, done: done ?? this.done, alerted: alerted ?? this.alerted);

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'due': due?.toIso8601String(),
    'done': done, 'alerted': alerted,
  };

  factory StudyTask.fromJson(Map<String, dynamic> map) => StudyTask(
    (map['id'] ?? '').toString(), (map['title'] ?? '').toString(),
    due: DateTime.tryParse((map['due'] ?? '').toString()),
    done: map['done'] == true, alerted: map['alerted'] == true,
  );
}

class StudyTracker extends ChangeNotifier with WidgetsBindingObserver {
  StudyTracker(this.prefs, this.storageKey, this.onReminder) {
    _load();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _checkReminders();
  }

  final SharedPreferences prefs;
  final String storageKey;
  final void Function(StudyTask) onReminder;
  final Map<String, int> _days = {};
  final List<StudyTask> _tasks = [];
  DateTime? _lastTick;
  Timer? _timer;
  int _elapsedTicks = 0;
  bool running = false;
  int dailyGoal = 120;
  int weeklyGoal = 840;

  void _load() {
    try {
      final data = jsonDecode(prefs.getString(storageKey) ?? '{}') as Map;
      for (final entry in ((data['days'] as Map?) ?? {}).entries) {
        final seconds = (entry.value as num?)?.toInt() ?? 0;
        if (seconds >= 0 && DateTime.tryParse(entry.key.toString()) != null) {
          _days[entry.key.toString()] = seconds;
        }
      }
      dailyGoal = ((data['dailyGoal'] as num?)?.toInt() ?? 120).clamp(1, 1440).toInt();
      weeklyGoal = ((data['weeklyGoal'] as num?)?.toInt() ?? 840).clamp(1, 10080).toInt();
      for (final value in (data['tasks'] as List?) ?? []) {
        if (value is Map) {
          final task = StudyTask.fromJson(Map<String, dynamic>.from(value));
          if (task.title.isNotEmpty) _tasks.add(task);
        }
      }
    } catch (_) {
      // Safely start with empty local data when an older record is malformed.
    }
  }

  void _save() {
    unawaited(prefs.setString(storageKey, jsonEncode({
      'days': _days,
      'dailyGoal': dailyGoal,
      'weeklyGoal': weeklyGoal,
      'tasks': _tasks.map((task) => task.toJson()).toList(),
    })));
  }

  int get todaySeconds => _days[studyDayKey(DateTime.now())] ?? 0;
  int get weekSeconds => StudyStats.weekSeconds(_days, DateTime.now());
  int get currentStreak => StudyStats.streak(_days, DateTime.now());
  int get highestStreak => StudyStats.bestStreak(_days);
  List<String> get recentBreaks => StudyStats.recentBreaks(_days);
  List<StudyTask> get tasks => List.unmodifiable(_tasks);
  int get pendingCount => _tasks.where((task) => !task.done).length;

  void _tick() {
    if (running) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastTick ?? now).inSeconds;
      if (elapsed > 0) {
        final key = studyDayKey(now);
        _days[key] = (_days[key] ?? 0) + elapsed;
        _lastTick = now;
        if (++_elapsedTicks % 5 == 0) _save();
        notifyListeners();
      }
    }
    _checkReminders();
  }

  void start() {
    if (running) return;
    running = true;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _tick();
    running = false;
    _lastTick = null;
    _save();
    notifyListeners();
  }

  void setGoals(int daily, int weekly) {
    dailyGoal = daily.clamp(1, 1440).toInt();
    weeklyGoal = weekly.clamp(1, 10080).toInt();
    _save();
    notifyListeners();
  }

  void addTask(String title, DateTime? due) {
    if (title.trim().isEmpty) return;
    _tasks.insert(0, StudyTask(DateTime.now().microsecondsSinceEpoch.toString(),
        title.trim(), due: due));
    _save();
    notifyListeners();
    _checkReminders();
  }

  void toggleTask(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _tasks[i] = _tasks[i].change(done: !_tasks[i].done);
    _save();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  void _checkReminders() {
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (!task.done && !task.alerted &&
          task.due != null && !task.due!.isAfter(now)) {
        _tasks[i] = task.change(alerted: true);
        changed = true;
        onReminder(task);
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
    if (state == AppLifecycleState.resumed) _checkReminders();
  }

  @override
  void dispose() {
    pause();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final studyTrackerProvider = ChangeNotifierProvider<StudyTracker>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'guest';
  return StudyTracker(ref.read(sharedPrefsProvider), 'hyzen_study_v1_$uid', (task) {
    ref.read(notificationsProvider.notifier).addLocalReminder(
        'Study reminder', task.title, task.id);
  });
});
