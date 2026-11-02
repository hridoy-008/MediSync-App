import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../core/notifications/local_notification_scheduler.dart';
import '../../../core/notifications/notification_channels.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/config_repository.dart';
import 'alarm_session_service.dart';

/// Opens the alarm screen when a wake-up alarm is ringing — from a notification
/// tap/action, a full-screen launch, or the app returning to the foreground.
class AlarmLauncher {
  AlarmLauncher._();
  static const _log = AppLogger('AlarmLauncher');

  /// The notification id and payload of the ringing wake-up alarm, if any.
  static Future<({int id, ReminderPayload? payload})?> ringingAlarm(
      FlutterLocalNotificationsPlugin plugin) async {
    try {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final active = await android?.getActiveNotifications() ??
          <ActiveNotification>[];
      for (final n in active) {
        if (NotificationChannels.isWakeAlarmChannel(n.channelId) &&
            n.id != null) {
          return (id: n.id!, payload: ReminderPayload.decode(n.payload));
        }
      }
    } catch (e) {
      _log.w('Could not read active notifications: $e');
    }
    return null;
  }

  static Future<void> openIfRinging(
    FlutterLocalNotificationsPlugin plugin, {
    ReminderPayload? hint,
  }) async {
    final ringing = await ringingAlarm(plugin);
    ReminderPayload? payload = ringing?.payload;

    if (ringing == null) {
      // Active-notification lookup is Android-only; elsewhere trust the tap.
      if (Platform.isAndroid ||
          hint == null ||
          hint.reminderId != LocalNotificationScheduler.wakeReminderId) {
        return;
      }
      final cfg = (await Get.find<ConfigRepository>().getSleep()).valueOrNull;
      if (cfg != null && !cfg.quizAlarmEnabled) return;
      payload = hint;
    }

    final service = AlarmSessionService.instance;
    await service.begin(payload?.scheduledTime);
    if (!service.isActive) return;

    final route = Get.currentRoute;
    if (route == AppRoutes.activeAlarm || route == AppRoutes.quiz) return;
    Get.toNamed(AppRoutes.activeAlarm, arguments: payload);
  }
}
