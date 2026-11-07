// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../notifications/notifications_screen.dart';
import 'study_notifications.dart';

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
    if ((days[studyDayKey(day)] ?? 0) < 900) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while ((days[studyDayKey(day)] ?? 0) >= 900) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static int bestStreak(Map<String, int> days) {
    final dates = days.keys.where((k) => (days[k] ?? 0) >= 900).toList()..sort();
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
    final dates = days.keys.where((k) => (days[k] ?? 0) >= 900).toList()..sort();
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
  const StudyTask(
    this.id, this.title, {
    this.due, this.done = false, this.alerted = false,
    this.kind = 'task', this.category = 'General', this.priority = 'medium',
    this.repeat = 'none', this.estimatedMinutes = 30, this.leadMinutes = 0,
    this.enabled = true,
  });
  final String id;
  final String title;
  final DateTime? due;
  final bool done;
  final bool alerted;
  final bool enabled;
  final String kind, category, priority, repeat;
  final int estimatedMinutes, leadMinutes;

  StudyTask change({bool? done, bool? alerted, bool? enabled}) => StudyTask(
    id, title,
    due: due, done: done ?? this.done, alerted: alerted ?? this.alerted,
    enabled: enabled ?? this.enabled, kind: kind, category: category,
    priority: priority, repeat: repeat, estimatedMinutes: estimatedMinutes,
    leadMinutes: leadMinutes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'due': due?.toIso8601String(),
    'done': done, 'alerted': alerted, 'enabled': enabled, 'kind': kind,
    'category': category, 'priority': priority, 'repeat': repeat,
    'estimatedMinutes': estimatedMinutes, 'leadMinutes': leadMinutes,
  };

  factory StudyTask.fromJson(Map<String, dynamic> map) => StudyTask(
    (map['id'] ?? '').toString(), (map['title'] ?? '').toString(),
    due: DateTime.tryParse((map['due'] ?? '').toString()),
    done: map['done'] == true, alerted: map['alerted'] == true,
    kind: (map['kind'] ?? 'task').toString(),
    category: (map['category'] ?? 'General').toString(),
    priority: (map['priority'] ?? 'medium').toString(),
    repeat: (map['repeat'] ?? 'none').toString(),
    estimatedMinutes: ((map['estimatedMinutes'] as num?)?.toInt() ?? 30).clamp(1, 1440).toInt(),
    leadMinutes: ((map['leadMinutes'] as num?)?.toInt() ?? 0).clamp(0, 120).toInt(),
    enabled: map['enabled'] != false,
  );
}

class StudyTracker extends ChangeNotifier with WidgetsBindingObserver {
  StudyTracker(this.prefs, this.storageKey, this.onReminder) {
    _load();
    WidgetsBinding.instance.addObserver(this);
    _checkReminders();
    _manageTicker();
    // Restore alarms when the user returns after an update or device reboot.
    for (final task in _tasks) {
      if (task.enabled && !task.done && task.due != null) {
        unawaited(_scheduleDevice(task));
      }
    }
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
  Map<String, int> get days => Map.unmodifiable(_days);
  List<StudyTask> get tasks => List.unmodifiable(_tasks.where((t) => t.kind == 'task'));
  List<StudyTask> get reminders => List.unmodifiable(_tasks.where((t) => t.kind == 'reminder'));
  int get completedTasks => _tasks.where((t) => t.kind == 'task' && t.done).length;
  int get pendingCount => _tasks.where((task) => task.kind == 'task' && !task.done).length;

  /// Do not leave an idle periodic timer alive in the app or widget tests.
  /// Only tick while studying or awaiting a due in-app reminder.
  void _manageTicker() {
    final needed = running ||
        _tasks.any((t) => !t.done && !t.alerted && t.due != null);
    if (needed && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!needed && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

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
    _manageTicker();
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _tick();
    running = false;
    _lastTick = null;
    _manageTicker();
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
    final task = StudyTask(DateTime.now().microsecondsSinceEpoch.toString(),
        title.trim(), due: due);
    _tasks.insert(0, task);
    if (due != null) unawaited(_scheduleDevice(task));
    _save();
    notifyListeners();
    _checkReminders();
    _manageTicker();
  }

  void toggleTask(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _tasks[i] = _tasks[i].change(done: !_tasks[i].done);
    if (_tasks[i].done) {
      unawaited(StudyNotificationScheduler.instance.cancel(id));
    } else {
      unawaited(_scheduleDevice(_tasks[i]));
    }
    _manageTicker();
    _save();
    notifyListeners();
  }

  void deleteTask(String id) {
    unawaited(StudyNotificationScheduler.instance.cancel(id));
    _tasks.removeWhere((t) => t.id == id);
    _manageTicker();
    _save();
    notifyListeners();
  }

  Future<void> _scheduleDevice(StudyTask task) async {
    if (!task.enabled || task.done || task.due == null) return;
    await StudyNotificationScheduler.instance.schedule(
      key: task.id, title: task.title, due: task.due!,
      repeat: task.repeat, leadMinutes: task.leadMinutes,
      route: '/study-goals',
    );
  }

  void addDetailedTask(
    String title, {
    String category = 'General',
    String priority = 'medium',
    int estimatedMinutes = 30,
    DateTime? due,
  }) {
    if (title.trim().isEmpty) return;
    final task = StudyTask(DateTime.now().microsecondsSinceEpoch.toString(),
      title.trim(), due: due, category: category, priority: priority,
      estimatedMinutes: estimatedMinutes);
    _tasks.insert(0, task);
    if (due != null) unawaited(_scheduleDevice(task));
    _save();
    notifyListeners();
    _manageTicker();
  }

  void addReminder(
    String title, DateTime due, {
    String type = 'Study',
    String repeat = 'none',
    int leadMinutes = 0,
  }) {
    if (title.trim().isEmpty) return;
    final reminder = StudyTask(DateTime.now().microsecondsSinceEpoch.toString(),
      title.trim(), due: due, kind: 'reminder', category: type,
      repeat: repeat, leadMinutes: leadMinutes);
    _tasks.insert(0, reminder);
    unawaited(_scheduleDevice(reminder));
    _save();
    notifyListeners();
    _manageTicker();
  }

  void toggleReminder(String id) {
    final index = _tasks.indexWhere((t) => t.id == id && t.kind == 'reminder');
    if (index < 0) return;
    final updated = _tasks[index].change(enabled: !_tasks[index].enabled);
    _tasks[index] = updated;
    if (updated.enabled) {
      unawaited(_scheduleDevice(updated));
    } else {
      unawaited(StudyNotificationScheduler.instance.cancel(id));
    }
    _save();
    notifyListeners();
    _manageTicker();
  }

  void _checkReminders() {
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (!task.done && task.enabled && !task.alerted &&
          task.repeat == 'none' && task.due != null && !task.due!.isAfter(now)) {
        _tasks[i] = task.change(alerted: true);
        changed = true;
        onReminder(task);
      }
    }
    if (changed) {
      _manageTicker();
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
