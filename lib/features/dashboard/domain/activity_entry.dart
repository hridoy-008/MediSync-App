import 'package:equatable/equatable.dart';

import '../../../domain/enums.dart';

enum ActivityCategory {
  medication,
  meal,
  water,
  exercise,
  sleep,
  other,
}

enum ActivityStatus {
  completed,
  missed,
  snoozed,
  skipped,
}

class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.category,
    required this.title,
    this.subtitle,
    required this.timestamp,
    required this.status,
    this.details,
    this.rawAction,
  });

  final String id;
  final ActivityCategory category;
  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final ActivityStatus status;
  final String? details;
  final ReminderAction? rawAction;

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        subtitle,
        timestamp,
        status,
        details,
        rawAction,
      ];
}
