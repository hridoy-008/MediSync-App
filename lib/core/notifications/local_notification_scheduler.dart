import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/configs.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/enums.dart';
import '../data/local_store.dart';
import '../localization/locale_controller.dart';
import '../utils/bangla_numerals.dart';
import '../utils/logger.dart';
import 'notification_channels.dart';
import 'reminder_action_handler.dart';
import 'reminder_payload.dart';
import 'reminder_scheduler.dart';

/// flutter_local_notifications + timezone implementation of [ReminderScheduler].
///
/// Reliability strategy (TRD §6):
/// - exact alarms (`exactAllowWhileIdle`) for time-critical firing;
/// - a **rolling window**: schedule the next [windowDays] of occurrences and top
///   up on app open — keeps iOS under its 64-notification cap and survives kill;
/// - the OS scheduler is a cache; everything is reconstructable from the Hive
///   mirror via each reminder's recurrence rule.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;
  static const _log = AppLogger('Scheduler');

  /// Id of the reminder that acts as the Wake-Up Alarm.
  static const wakeReminderId = 'rem_sleep_wake';

  /// How far ahead to materialize occurrences.
  static const int windowDays = 7;

  /// Global cap to stay safely under iOS' 64 pending-notification limit.
  static const int maxScheduled = 58;

  bool _inited = false;

  @override
  Future<void> init() async {
    if (_inited) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        final clean = name.replaceAll(' ', '_');
        tz.setLocalLocation(tz.getLocation(clean));
      }
    } catch (e) {
      _log.w('Timezone detect failed, defaulting to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    // Register Android channels up front.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final ch in NotificationChannels.all) {
      await android?.createNotificationChannel(ch);
    }
    // Retire the old Smart Wake-Up Alarm channel on existing installs.
    await android?.deleteNotificationChannel('smart_wakeup_alarm_channel');

    _inited = true;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    if (!reminder.enabled) return;
    final now = DateTime.now();
    final until = now.add(const Duration(days: windowDays));
    final occurrences = reminder.recurrence.occurrencesBetween(now, until);

    for (final fireTime in occurrences) {
      await _scheduleOne(reminder, fireTime);
    }
  }

  @override
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await _cancelAllExceptRingingAlarm();
    final now = DateTime.now();
    final until = now.add(const Duration(days: windowDays));

    // Build a flat, time-sorted list of (reminder, fireTime), prioritizing
    // medicine reminders, then apply the global cap.
    final pending = <({Reminder reminder, DateTime time})>[];
    for (final r in reminders.where((r) => r.enabled)) {
      for (final t in r.recurrence.occurrencesBetween(now, until)) {
        pending.add((reminder: r, time: t));
      }
    }

    pending.sort((a, b) {
      final pa = a.reminder.type == ReminderType.medicine ? 0 : 1;
      final pb = b.reminder.type == ReminderType.medicine ? 0 : 1;
      if (pa != pb) return pa - pb;
      return a.time.compareTo(b.time);
    });

    var count = 0;
    for (final item in pending) {
      if (count >= maxScheduled) {
        _log.w('Hit maxScheduled cap ($maxScheduled); '
            'remaining occurrences will be topped up on next app open.');
        break;
      }
      await _scheduleOne(item.reminder, item.time);
      count++;
    }
    _log.i(
        'Scheduled $count occurrences across ${reminders.length} reminders.');
  }

  Future<void> _scheduleOne(Reminder reminder, DateTime fireTime) async {
    final nowTz = tz.TZDateTime.now(tz.local);
    final tzTime = tz.TZDateTime.from(fireTime, tz.local);
    if (!tzTime.isAfter(nowTz)) return;

    final wakeCfg = reminder.id == wakeReminderId ? await _readSleepConfig() : null;
    final isQuizAlarm = wakeCfg != null && wakeCfg.quizAlarmEnabled;
    final channel = isQuizAlarm
        ? NotificationChannels.wakeAlarmFor(
            sound: wakeCfg.alarmSoundEnabled,
            vibrate: wakeCfg.alarmVibrate,
          )
        : NotificationChannels.forType(reminder.type);

    final payload = ReminderPayload(
      reminderId: reminder.id,
      type: reminder.type,
      scheduledTime: fireTime,
    ).encode();

    final mealTitle = reminder.isMeal &&
            !reminder.title.toLowerCase().contains('reminder') &&
            !reminder.title.contains('রিমাইন্ডার')
        ? '${reminder.title} Reminder'
        : reminder.title;
    final doseMessage =
        reminder.type == ReminderType.medicine ? reminder.doseMessageAt(fireTime) : null;
    final title = isQuizAlarm
        ? 'Wake Up!'
        : (doseMessage != null ? 'Medicine Reminder' : mealTitle);
    final body = isQuizAlarm
        ? 'Solve the quiz to stop the alarm'
        : doseMessage ??
            (reminder.subtitle.isNotEmpty
            ? reminder.subtitle
            : (reminder.isMeal
                ? "It's time for your ${reminder.title.toLowerCase()}."
                : null));

    final androidDetailsExact = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: isQuizAlarm ? Priority.max : Priority.high,
      category: isQuizAlarm || reminder.type == ReminderType.medicine
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      fullScreenIntent: isQuizAlarm || reminder.type == ReminderType.medicine,
      ongoing: isQuizAlarm,
      autoCancel: !isQuizAlarm,
      audioAttributesUsage: isQuizAlarm
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      // FLAG_INSISTENT: sound/vibration repeat until the notification is cancelled.
      additionalFlags: isQuizAlarm ? Int32List.fromList(<int>[4]) : null,
      actions: _actionsFor(reminder, isQuizAlarm),
    );

    final androidDetailsSafe = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: isQuizAlarm ? Priority.max : Priority.high,
      category: isQuizAlarm || reminder.type == ReminderType.medicine
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      fullScreenIntent: false,
      ongoing: isQuizAlarm,
      autoCancel: !isQuizAlarm,
      audioAttributesUsage: isQuizAlarm
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      additionalFlags: isQuizAlarm ? Int32List.fromList(<int>[4]) : null,
      actions: _actionsFor(reminder, isQuizAlarm),
    );

    const darwinDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'reminder_actions',
    );

    try {
      await _plugin.zonedSchedule(
        reminder.notificationIdFor(fireTime),
        title,
        body,
        tzTime,
        NotificationDetails(
          android: androidDetailsExact,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      _log.w(
          'Exact or full-screen schedule failed, retrying with safe fallback: $e');
      try {
        await _plugin.zonedSchedule(
          reminder.notificationIdFor(fireTime),
          title,
          body,
          tzTime,
          NotificationDetails(
            android: androidDetailsSafe,
            iOS: darwinDetails,
            macOS: darwinDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        _log.e('Failed to schedule notification entirely: $e2');
      }
    }
  }

  List<AndroidNotificationAction> _actionsFor(
      Reminder reminder, bool isQuizAlarm) {
    if (isQuizAlarm) {
      return const [
        AndroidNotificationAction(
          NotificationActions.solveQuiz,
          'Solve Quiz',
          showsUserInterface: true,
        ),
      ];
    }
    if (reminder.type == ReminderType.water ||
        reminder.type == ReminderType.sleep) {
      return const [
        AndroidNotificationAction(NotificationActions.taken, 'Done',
            showsUserInterface: false),
      ];
    }
    if (reminder.isMeal) {
      return const [
        AndroidNotificationAction(NotificationActions.taken, 'Taken',
            showsUserInterface: false),
        AndroidNotificationAction(NotificationActions.missed, 'Missed',
            showsUserInterface: false),
      ];
    }
    if (reminder.doseSlots.isNotEmpty) {
      // Prescription dose reminders: explicit Taken / Missed (max 3 actions).
      return const [
        AndroidNotificationAction(NotificationActions.taken, 'Taken',
            showsUserInterface: false),
        AndroidNotificationAction(NotificationActions.missed, 'Missed',
            showsUserInterface: false),
        AndroidNotificationAction(NotificationActions.snooze, 'Snooze',
            showsUserInterface: false),
      ];
    }
    return const [
      AndroidNotificationAction(NotificationActions.taken, 'Taken',
          showsUserInterface: false),
      AndroidNotificationAction(NotificationActions.snooze, 'Snooze',
          showsUserInterface: false),
      AndroidNotificationAction(NotificationActions.skip, 'Skip',
          showsUserInterface: false),
    ];
  }

  @override
  Future<void> cancelReminder(Reminder reminder) async {
    final now = DateTime.now();
    final until = now.add(const Duration(days: windowDays + 1));
    for (final t in reminder.recurrence.occurrencesBetween(now, until)) {
      await _plugin.cancel(reminder.notificationIdFor(t));
    }
  }

  @override
  Future<void> cancelById(String reminderId) async {
    // Without the reminder's recurrence we can't target exact ids; the safe
    // path is a full reschedule by the caller. Kept for interface completeness.
    _log.w('cancelById($reminderId) — prefer cancelReminder/rescheduleAll.');
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Same as [cancelAll] but leaves a currently ringing wake-up alarm alone, so
  /// a reschedule (app open, 6-hourly maintenance) can never silence it.
  Future<void> _cancelAllExceptRingingAlarm() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ringing = <int>{};
    try {
      final active = await android?.getActiveNotifications() ?? const [];
      for (final n in active) {
        if (NotificationChannels.isWakeAlarmChannel(n.channelId) &&
            n.id != null) {
          ringing.add(n.id!);
        }
      }
    } catch (e) {
      _log.w('Could not inspect active notifications: $e');
    }
    if (ringing.isEmpty) {
      await _plugin.cancelAll();
      return;
    }
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (!ringing.contains(p.id)) await _plugin.cancel(p.id);
    }
    for (final n in await android?.getActiveNotifications() ?? const []) {
      if (n.id != null && !ringing.contains(n.id)) await _plugin.cancel(n.id!);
    }
  }

  Future<SleepConfig> _readSleepConfig() async {
    try {
      await LocalStore.instance.init();
      final raw = LocalStore.instance.singletons.get('sleep');
      return raw == null
          ? const SleepConfig()
          : SleepConfig.fromMap(LocalStore.normalize(raw));
    } catch (_) {
      return const SleepConfig();
    }
  }

  @override
  Future<void> showLowStockNotification({
    required String medicineName,
    required int stockCount,
    required int threshold,
    required bool isOutOfStock,
  }) async {
    final isBangla = Get.isRegistered<LocaleController>() &&
        Get.find<LocaleController>().isBangla;

    final title = isOutOfStock
        ? (isBangla ? 'স্টক শেষের সতর্কতা' : 'Out of Stock Alert')
        : (isBangla ? 'কম স্টকের সতর্কতা' : 'Low Stock Alert');

    final countStr =
        isBangla ? BanglaNumerals.toBangla(stockCount) : stockCount.toString();

    final body = isOutOfStock
        ? (isBangla
            ? '$medicineName-এর স্টক শেষ (০টি বাকি)। দ্রুত পুনরায় কিনুন।'
            : '$medicineName is out of stock (0 left). Please refill immediately.')
        : (isBangla
            ? '$medicineName-এর স্টক কমে এসেছে ($countStrটি বাকি)। ইনভেন্টরি দেখতে ট্যাপ করুন।'
            : '$medicineName is running low ($countStr left). Tap to view inventory.');

    final notificationId = ('low_stock_$medicineName'.hashCode & 0x7FFFFFFF);
    final payload = ReminderPayload(
      reminderId: 'low_stock_$medicineName',
      type: ReminderType.medicine,
      scheduledTime: DateTime.now(),
    ).encode();

    final channel = NotificationChannels.lowStock;
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _plugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      _log.e('Failed to post low stock notification: $e');
    }
  }
}
