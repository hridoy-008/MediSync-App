import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/enums.dart';
import '../data/local_store.dart';
import '../utils/logger.dart';
import 'notification_channels.dart';
import 'reminder_payload.dart';

const _log = AppLogger('ReminderAction');
final _uuid = Uuid();

/// App-set hook so foreground taps can refresh reactive UI (set in main).
typedef ForegroundActionCallback = void Function(
    ReminderPayload payload, String? actionId);
ForegroundActionCallback? appForegroundActionCallback;

/// Foreground tap/action: persist the log, then let the app refresh UI.
@pragma('vm:entry-point')
void onForegroundNotificationResponse(NotificationResponse response) async {
  final payload = ReminderPayload.decode(response.payload);
  if (payload == null) return;
  await _persistAction(payload, response.actionId);
  appForegroundActionCallback?.call(payload, response.actionId);
}

/// Background isolate action (app killed) — no GetX/Firebase available, so we
/// open Hive directly and write the adherence log. This is why the mirror is
/// Firebase-independent (TRD §6).
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  final payload = ReminderPayload.decode(response.payload);
  if (payload == null) return;
  await _persistAction(payload, response.actionId);
}

Future<void> _persistAction(ReminderPayload payload, String? actionId) async {
  try {
    await LocalStore.instance.init();
    final action = _actionFrom(actionId);
    final log = ReminderLog(
      id: _logId(payload),
      reminderId: payload.reminderId,
      type: payload.type,
      scheduledTime: payload.scheduledTime,
      firedAt: payload.scheduledTime,
      confirmedAt: DateTime.now(),
      action: action,
      status: _statusFrom(action),
    );
    await LocalStore.instance.logs.put(log.id, log.toMap());

    if (action == ReminderAction.snoozed) {
      await _scheduleSnooze(payload);
    }
  } catch (e, s) {
    _log.e('persistAction failed', e, s);
  }
}

/// Deterministic log id per (reminder, occurrence) so repeated taps upsert.
String _logId(ReminderPayload p) =>
    'log_${p.reminderId}_${p.scheduledTime.millisecondsSinceEpoch}';

ReminderAction _actionFrom(String? actionId) => switch (actionId) {
      NotificationActions.taken => ReminderAction.taken,
      NotificationActions.snooze => ReminderAction.snoozed,
      NotificationActions.skip => ReminderAction.skipped,
      _ => ReminderAction.taken, // tapping body = acknowledged
    };

ReminderStatus _statusFrom(ReminderAction a) => switch (a) {
      ReminderAction.taken => ReminderStatus.taken,
      ReminderAction.snoozed => ReminderStatus.snoozed,
      ReminderAction.skipped => ReminderStatus.skipped,
      ReminderAction.missed => ReminderStatus.missed,
    };

/// Re-fire in 10 minutes from a fresh plugin instance (works in the background
/// isolate). Uses zonedSchedule so it actually fires later, not immediately.
Future<void> _scheduleSnooze(ReminderPayload payload) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // default tz.local (UTC) is acceptable for a relative +10 min snooze.
      tz.setLocalLocation(tz.UTC);
    }

    final when = DateTime.now().add(const Duration(minutes: 10));
    final channel = NotificationChannels.forType(payload.type);
    await plugin.zonedSchedule(
      _uuid.v4().hashCode & 0x7FFFFFFF,
      'Reminder (snoozed)',
      'Tap when done',
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: channel.importance,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: ReminderPayload(
        reminderId: payload.reminderId,
        type: payload.type,
        scheduledTime: when,
      ).encode(),
    );
  } catch (e) {
    if (kDebugMode) _log.w('snooze schedule failed: $e');
  }
}
