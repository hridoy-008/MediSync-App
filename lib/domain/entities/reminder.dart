import 'package:equatable/equatable.dart';

import '../../core/utils/recurrence.dart';
import '../enum_codec.dart';
import '../enums.dart';

/// The schedulable unit (TRD §4). Materialized into the Hive mirror that the
/// alarm engine + boot receiver read — independent of Firebase.
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.recurrence,
    this.refId,
    this.subtitle = '',
    this.foodTiming,
    this.mealType,
    this.graceWindowMins = 30,
    this.enabled = true,
    this.createdAt,
    this.stockCount,
    this.lowStockThreshold,
    this.stockAlertEnabled = false,
  });

  final String id;
  final ReminderType type;
  final String title;
  final String subtitle;

  /// Links back to a Medicine/MealConfig/etc.
  final String? refId;

  final RecurrenceRule recurrence;
  final FoodTiming? foodTiming; // for food-relative medicines
  final MealType? mealType; // for meal reminders
  final int graceWindowMins; // missed-event window (PRD P0-9)
  final bool enabled;
  final DateTime? createdAt;

  // Stock inventory tracking fields (smart alerts)
  final int? stockCount;
  final int? lowStockThreshold;
  final bool stockAlertEnabled;

  bool get isLowStock => (stockAlertEnabled && stockCount != null && lowStockThreshold != null)
      ? stockCount! <= lowStockThreshold!
      : false;

  Reminder copyWith({
    String? title,
    String? subtitle,
    RecurrenceRule? recurrence,
    FoodTiming? foodTiming,
    int? graceWindowMins,
    bool? enabled,
    int? stockCount,
    int? lowStockThreshold,
    bool? stockAlertEnabled,
  }) {
    return Reminder(
      id: id,
      type: type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      refId: refId,
      recurrence: recurrence ?? this.recurrence,
      foodTiming: foodTiming ?? this.foodTiming,
      mealType: mealType,
      graceWindowMins: graceWindowMins ?? this.graceWindowMins,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      stockCount: stockCount ?? this.stockCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      stockAlertEnabled: stockAlertEnabled ?? this.stockAlertEnabled,
    );
  }

  /// Stable 31-bit notification id derived from the reminder id + fire time —
  /// flutter_local_notifications requires an int id per scheduled notification.
  int notificationIdFor(DateTime fireTime) {
    final base = id.hashCode ^ fireTime.millisecondsSinceEpoch.hashCode;
    return base & 0x7FFFFFFF;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'refId': refId,
        'recurrence': recurrence.toMap(),
        'foodTiming': foodTiming?.name,
        'mealType': mealType?.name,
        'graceWindowMins': graceWindowMins,
        'enabled': enabled,
        'createdAt': createdAt?.toIso8601String(),
        'stockCount': stockCount,
        'lowStockThreshold': lowStockThreshold,
        'stockAlertEnabled': stockAlertEnabled,
      };

  factory Reminder.fromMap(Map<String, dynamic> m) => Reminder(
        id: m['id'] as String,
        type: enumByName(ReminderType.values, m['type'], ReminderType.medicine),
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String? ?? '',
        refId: m['refId'] as String?,
        recurrence: RecurrenceRule.fromMap(
            Map<String, dynamic>.from(m['recurrence'] as Map)),
        foodTiming: enumByNameOrNull(FoodTiming.values, m['foodTiming']),
        mealType: enumByNameOrNull(MealType.values, m['mealType']),
        graceWindowMins: (m['graceWindowMins'] as num?)?.toInt() ?? 30,
        enabled: m['enabled'] as bool? ?? true,
        createdAt: m['createdAt'] == null
            ? null
            : DateTime.parse(m['createdAt'] as String),
        stockCount: m['stockCount'] as int?,
        lowStockThreshold: m['lowStockThreshold'] as int?,
        stockAlertEnabled: m['stockAlertEnabled'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        recurrence,
        enabled,
        stockCount,
        lowStockThreshold,
        stockAlertEnabled,
      ];
}

/// One fired-and-resolved occurrence — the adherence source data (TRD §4).
class ReminderLog extends Equatable {
  const ReminderLog({
    required this.id,
    required this.reminderId,
    required this.type,
    required this.scheduledTime,
    this.firedAt,
    this.confirmedAt,
    this.action = ReminderAction.missed,
    this.status = ReminderStatus.pending,
  });

  final String id;
  final String reminderId;
  final ReminderType type;
  final DateTime scheduledTime;
  final DateTime? firedAt;
  final DateTime? confirmedAt;
  final ReminderAction action;
  final ReminderStatus status;

  ReminderLog copyWith({
    DateTime? firedAt,
    DateTime? confirmedAt,
    ReminderAction? action,
    ReminderStatus? status,
  }) {
    return ReminderLog(
      id: id,
      reminderId: reminderId,
      type: type,
      scheduledTime: scheduledTime,
      firedAt: firedAt ?? this.firedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      action: action ?? this.action,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'reminderId': reminderId,
        'type': type.name,
        'scheduledTime': scheduledTime.toIso8601String(),
        'firedAt': firedAt?.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'action': action.name,
        'status': status.name,
      };

  factory ReminderLog.fromMap(Map<String, dynamic> m) => ReminderLog(
        id: m['id'] as String,
        reminderId: m['reminderId'] as String,
        type: enumByName(ReminderType.values, m['type'], ReminderType.medicine),
        scheduledTime: DateTime.parse(m['scheduledTime'] as String),
        firedAt: m['firedAt'] == null
            ? null
            : DateTime.parse(m['firedAt'] as String),
        confirmedAt: m['confirmedAt'] == null
            ? null
            : DateTime.parse(m['confirmedAt'] as String),
        action: enumByName(ReminderAction.values, m['action'], ReminderAction.missed),
        status: enumByName(ReminderStatus.values, m['status'], ReminderStatus.pending),
      );

  @override
  List<Object?> get props => [id, reminderId, scheduledTime, action, status];
}
