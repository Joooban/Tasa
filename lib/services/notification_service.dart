import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _reminderChannelId = 'tasa_daily_reminder';
const _reminderNotificationId = 1;

/// Gentle, opt-in daily reminder — off by default, never a dark-pattern nag.
/// Permission is requested only when the user turns this on in Settings, not
/// upfront at launch.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _reminderNotificationId,
      'Log today\'s cup?',
      'A quick tap keeps your cupboard up to date — no pressure either way.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Daily reminder',
          channelDescription: 'A gentle once-a-day nudge to log a cup, if you had one.',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(_reminderNotificationId);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
