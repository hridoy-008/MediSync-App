import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';

/// One concrete occurrence on the Today timeline (Design §5.2).
class TimelineItem {
  const TimelineItem({
    required this.reminder,
    required this.scheduledTime,
    required this.status,
    this.linkedMedicineSummary,
    this.preMealSummary,
  });

  final Reminder reminder;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final String? linkedMedicineSummary;
  final String? preMealSummary;

  ReminderType get type => reminder.type;
  bool get isPending => status == ReminderStatus.pending;

  TimelineItem copyWith({
    ReminderStatus? status,
    String? linkedMedicineSummary,
    String? preMealSummary,
  }) =>
      TimelineItem(
        reminder: reminder,
        scheduledTime: scheduledTime,
        status: status ?? this.status,
        linkedMedicineSummary:
            linkedMedicineSummary ?? this.linkedMedicineSummary,
        preMealSummary: preMealSummary ?? this.preMealSummary,
      );
}
