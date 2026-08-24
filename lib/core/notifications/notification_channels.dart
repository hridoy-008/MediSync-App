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

  static List<AndroidNotificationChannel> all = const [
    medicine,
    meal,
    water,
    sleep,
    missed,
    lowStock,
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
}
