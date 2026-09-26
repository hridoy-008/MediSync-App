import '../../../domain/entities/configs.dart';
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
    this.mealConfig,
  });

  final Reminder reminder;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final String? linkedMedicineSummary;
  final String? preMealSummary;
  final MealConfig? mealConfig;

  ReminderType get type => reminder.type;
  bool get isPending => status == ReminderStatus.pending;
  String? get mealDescription => mealConfig?.description;
  String? get mealImagePath => mealConfig?.imagePath;
  String? get recommendedFood => mealConfig?.recommendedFood;

  TimelineItem copyWith({
    ReminderStatus? status,
    String? linkedMedicineSummary,
    String? preMealSummary,
    MealConfig? mealConfig,
  }) =>
      TimelineItem(
        reminder: reminder,
        scheduledTime: scheduledTime,
        status: status ?? this.status,
        linkedMedicineSummary:
            linkedMedicineSummary ?? this.linkedMedicineSummary,
        preMealSummary: preMealSummary ?? this.preMealSummary,
        mealConfig: mealConfig ?? this.mealConfig,
      );
}
