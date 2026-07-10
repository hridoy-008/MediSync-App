import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/reminder.dart';
import '../data/local_store.dart';
import '../firebase/firebase_service.dart';
import '../firebase/remote_mirror.dart';
import '../data/repositories/reminder_repository_impl.dart';
import '../utils/logger.dart';
import 'local_notification_scheduler.dart';
import 'missed_event_service.dart';

/// Periodic + reboot maintenance — registered with android_alarm_manager_plus
/// (`rescheduleOnReboot: true`). Runs in its own isolate with NO Firebase:
/// it reads the Hive mirror, rebuilds the OS notification window, and runs the
/// missed-event check (TRD §6 "boot receiver re-registers from the mirror").
@pragma('vm:entry-point')
Future<void> reminderMaintenanceCallback() async {
  const log = AppLogger('Maintenance');
  try {
    await LocalStore.instance.init();

    // Read reminders directly from the mirror (no network, no Firebase).
    final reminders = LocalStore.instance.reminders.values
        .map((m) => Reminder.fromMap(LocalStore.normalize(m)))
        .where((r) => r.enabled)
        .toList();

    final plugin = FlutterLocalNotificationsPlugin();
    final scheduler = LocalNotificationScheduler(plugin);
    await scheduler.init();
    await scheduler.rescheduleAll(reminders);

    // Missed-event sweep. RemoteMirror is null-safe when Firebase is absent.
    final repo = ReminderRepositoryImpl(
      LocalStore.instance,
      RemoteMirror(FirebaseService.instance),
    );
    await MissedEventService(repo, plugin).checkAndFollowUp();

    log.i('Maintenance pass complete (${reminders.length} reminders).');
  } catch (e, s) {
    log.e('Maintenance pass failed', e, s);
  }
}
