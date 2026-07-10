import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../utils/logger.dart';
import 'notification_channels.dart';
import 'reminder_payload.dart';

/// Grace-window missed-event detection + gentle follow-up nudge (PRD P0-9,
/// Design §5.7). Called on app open and from the periodic maintenance alarm.
class MissedEventService {
  MissedEventService(this._reminders, this._plugin);
  final ReminderRepository _reminders;
  final FlutterLocalNotificationsPlugin _plugin;
  static const _log = AppLogger('MissedEvent');
  static final _uuid = Uuid();

  /// Look back over the last [lookbackHours] for occurrences whose grace window
  /// has elapsed with no user action; mark them missed and nudge once.
  Future<void> checkAndFollowUp({int lookbackHours = 12}) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(hours: lookbackHours));

    final reminders = (await _reminders.getEnabled()).valueOrNull ?? const [];
    final logs = (await _reminders.getLogs(from: from, to: now)).valueOrNull ??
        const [];
    final resolved = {
      for (final l in logs)
        if (l.action != ReminderAction.missed)
          '${l.reminderId}_${l.scheduledTime.millisecondsSinceEpoch}'
    };

    for (final r in reminders) {
      // Only nudge for medicine + meal (habit reminders aren't "missed").
      if (r.type == ReminderType.water || r.type == ReminderType.sleep) continue;

      for (final occ in r.recurrence.occurrencesBetween(from, now)) {
        final graceEnd = occ.add(Duration(minutes: r.graceWindowMins));
        if (graceEnd.isAfter(now)) continue; // still inside grace
        final key = '${r.id}_${occ.millisecondsSinceEpoch}';
        if (resolved.contains(key)) continue; // user acted

        await _markMissed(r, occ);
        await _nudge(r, occ);
      }
    }
  }

  Future<void> _markMissed(Reminder r, DateTime occ) async {
    final log = ReminderLog(
      id: 'log_${r.id}_${occ.millisecondsSinceEpoch}',
      reminderId: r.id,
      type: r.type,
      scheduledTime: occ,
      firedAt: occ,
      action: ReminderAction.missed,
      status: ReminderStatus.missed,
    );
    await _reminders.upsertLog(log);
  }

  Future<void> _nudge(Reminder r, DateTime occ) async {
    final timeLabel =
        '${occ.hour.toString().padLeft(2, '0')}:${occ.minute.toString().padLeft(2, '0')}';
    try {
      await _plugin.show(
        _uuid.v4().hashCode & 0x7FFFFFFF,
        r.title,
        "You haven't confirmed your $timeLabel dose — tap to update.",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'missed_channel',
            'Missed-dose follow-ups',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: ReminderPayload(
          reminderId: r.id,
          type: r.type,
          scheduledTime: occ,
        ).encode(),
      );
    } catch (e) {
      _log.w('nudge failed: $e');
    }
  }
}
