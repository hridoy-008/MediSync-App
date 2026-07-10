import '../../domain/enums.dart';

/// Encodes which reminder occurrence a notification belongs to, so action taps
/// can be logged against the exact scheduled time.
class ReminderPayload {
  const ReminderPayload({
    required this.reminderId,
    required this.type,
    required this.scheduledTime,
  });

  final String reminderId;
  final ReminderType type;
  final DateTime scheduledTime;

  String encode() =>
      '$reminderId|${type.name}|${scheduledTime.toIso8601String()}';

  static ReminderPayload? decode(String? raw) {
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final type = ReminderType.values
        .where((t) => t.name == parts[1])
        .cast<ReminderType?>()
        .firstWhere((_) => true, orElse: () => null);
    final time = DateTime.tryParse(parts[2]);
    if (type == null || time == null) return null;
    return ReminderPayload(
      reminderId: parts[0],
      type: type,
      scheduledTime: time,
    );
  }
}
