import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/enums.dart';

/// One channel per reminder type so users can tune behavior; medicine is high
/// importance with sound + full-screen alarm capability (TRD §6, Design §5.7).
class NotificationChannels {
  static const medicine = AndroidNotificationChannel(
    'medicine_channel',
    'Medicine reminders',
    description: 'Time-critical medication reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const meal = AndroidNotificationChannel(
    'meal_channel',
    'Meal reminders',
    description: 'Meal-time reminders',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const water = AndroidNotificationChannel(
    'water_channel',
    'Water reminders',
    description: 'Hydration reminders',
    importance: Importance.defaultImportance,
  );

  static const sleep = AndroidNotificationChannel(
    'sleep_channel',
    'Sleep reminders',
    description: 'Bedtime and wake reminders',
    importance: Importance.high,
  );

  static const missed = AndroidNotificationChannel(
    'missed_channel',
    'Missed-dose follow-ups',
    description: 'Gentle nudges when a dose is unconfirmed',
    importance: Importance.high,
  );

  static const lowStock = AndroidNotificationChannel(
    'low_stock_channel',
    'Low stock alerts',
    description: 'Alerts when medicine inventory is low or out of stock',
    importance: Importance.high,
    playSound: true,
  );

  // Wake-Up Alarm channels. Android fixes sound/vibration per channel, so the
  // user's sound/vibrate settings pick one of these four.
  static const wakeAlarm = AndroidNotificationChannel(
    'wake_alarm_channel',
    'Wake-Up Alarm',
    description: 'Wake-up alarm that rings until the quiz is solved',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const wakeAlarmSoundOnly = AndroidNotificationChannel(
    'wake_alarm_sound_channel',
    'Wake-Up Alarm (sound only)',
    description: 'Wake-up alarm without vibration',
    importance: Importance.max,
    playSound: true,
    enableVibration: false,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const wakeAlarmVibrateOnly = AndroidNotificationChannel(
    'wake_alarm_vibrate_channel',
    'Wake-Up Alarm (vibration only)',
    description: 'Wake-up alarm without sound',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
  );

  static const wakeAlarmSilent = AndroidNotificationChannel(
    'wake_alarm_silent_channel',
    'Wake-Up Alarm (silent)',
    description: 'Wake-up alarm without sound or vibration',
    importance: Importance.max,
    playSound: false,
    enableVibration: false,
  );

  static AndroidNotificationChannel wakeAlarmFor({
    required bool sound,
    required bool vibrate,
  }) =>
      sound
          ? (vibrate ? wakeAlarm : wakeAlarmSoundOnly)
          : (vibrate ? wakeAlarmVibrateOnly : wakeAlarmSilent);

  static bool isWakeAlarmChannel(String? id) =>
      id != null && id.startsWith('wake_alarm_');

  static List<AndroidNotificationChannel> all = const [
    medicine,
    meal,
    water,
    sleep,
    missed,
    lowStock,
    wakeAlarm,
    wakeAlarmSoundOnly,
    wakeAlarmVibrateOnly,
    wakeAlarmSilent,
  ];

  static AndroidNotificationChannel forType(ReminderType type) =>
      switch (type) {
        ReminderType.medicine => medicine,
        ReminderType.meal => meal,
        ReminderType.water => water,
        ReminderType.sleep => sleep,
      };
}

/// Notification action ids (quick actions on the reminder — Design §5.7).
class NotificationActions {
  static const taken = 'action_taken';
  static const snooze = 'action_snooze';
  static const skip = 'action_skip';
  static const open = 'action_open';
  static const missed = 'action_missed';
  static const solveQuiz = 'action_solve_quiz';
}
