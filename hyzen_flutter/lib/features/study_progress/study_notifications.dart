import 'reminder_plan.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Device-local Android/iOS alarms. They are not Firebase messages and do not
/// require the app to stay open or the phone to be online.
class StudyNotificationScheduler {
  StudyNotificationScheduler._();
  static final instance = StudyNotificationScheduler._();
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  void Function(String route)? onOpen;
  String? _pendingRoute;

  int idFor(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 16777619 & 0x7fffffff;
    }
    return hash;
  }

  Future<void> initialize() => _ready ??= _initialize();

  Future<void> _initialize() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC for absolute instants if platform timezone is missing.
    }
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestSoundPermission: false,
            requestAlertPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          _open(response.payload);
        },
      );
      final launched = await _plugin.getNotificationAppLaunchDetails();
      if (launched?.didNotificationLaunchApp == true) {
        _open(launched?.notificationResponse?.payload);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Notification setup unavailable: $error');
    }
  }

  void bindOpenHandler(void Function(String) handler) {
    onOpen = handler;
    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      handler(pending);
    }
  }

  void _open(String? payload) {
    final route = payload?.startsWith('/study-') == true
        ? payload!
        : '/study-goals';
    if (onOpen == null) {
      _pendingRoute = route;
    } else {
      onOpen!(route);
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancel(String key) async {
    if (kIsWeb) return;
    await initialize();
    try {
      for (var i = 0; i < 96; i++) {
        await _plugin.cancel(idFor('$key:$i'));
      }
    } catch (_) {}
  }

  Future<void> schedule({
    required String key,
    required String title,
    required DateTime due,
    String repeat = 'none',
    String route = '/study-goals',
    int leadMinutes = 0,
    List<int> weekdays = const [],
    int extraAlerts = 0,
    bool quiet = true,
    DateTime? until,
  }) async {
    if (kIsWeb) return;
    await initialize();
    await cancel(key);
    try {
      final now = DateTime.now();
      final notice = const NotificationDetails(
        android: AndroidNotificationDetails(
          'hyzen_study_v1',
          'Study and task reminders',
          channelDescription: 'Your scheduled study goals and tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      Future<void> put(
        int slot,
        DateTime time,
        DateTimeComponents? match,
      ) async {
        final when = tz.TZDateTime.from(time, tz.local);
        await _plugin.zonedSchedule(
          idFor('$key:$slot'),
          'PHARM D WITH HYZEN',
          title,
          when,
          notice,
          payload: route,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: match,
        );
      }

      final plan = reminderPlan(
        now: now,
        due: due,
        repeat: repeat,
        weekdays: weekdays,
        leadMinutes: leadMinutes,
        extraAlerts: extraAlerts,
        quiet: quiet,
        until: until,
      );
      for (var i = 0; i < plan.length; i++) {
        await put(
          i,
          plan[i].time,
          plan[i].weekly ? DateTimeComponents.dayOfWeekAndTime : null,
        );
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Could not schedule reminder: $error');
    }
  }
}
