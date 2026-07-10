import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import 'tokens.dart';

/// Fixed icon + accent color per reminder type so each domain is recognizable
/// at a glance (Design doc §3.4) — never color alone, always icon + label.
class ReminderVisuals {
  static IconData icon(ReminderType type) => switch (type) {
        ReminderType.medicine => Icons.medication_outlined,
        ReminderType.meal => Icons.restaurant_outlined,
        ReminderType.water => Icons.water_drop_outlined,
        ReminderType.sleep => Icons.bedtime_outlined,
      };

  static Color color(ReminderType type, AppColors c) => switch (type) {
        ReminderType.medicine => c.medicine,
        ReminderType.meal => c.meal,
        ReminderType.water => c.water,
        ReminderType.sleep => c.sleep,
      };

  static Color statusColor(ReminderStatus status, AppColors c) =>
      switch (status) {
        ReminderStatus.taken => c.success,
        ReminderStatus.missed => c.danger,
        ReminderStatus.snoozed => c.warning,
        ReminderStatus.skipped => c.onSurfaceMuted,
        ReminderStatus.pending => c.info,
      };
}
