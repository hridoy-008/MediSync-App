import 'package:add_2_calendar/add_2_calendar.dart';

import '../../domain/entities/reminder.dart';

class CalendarHelper {
  CalendarHelper._();

  static void addReminderToCalendar(Reminder reminder, DateTime scheduledTime) {
    final Event event = Event(
      title: 'MediSync: ${reminder.title}',
      description: reminder.subtitle.isNotEmpty
          ? reminder.subtitle
          : 'MediSync Health Reminder',
      location: 'MediSync App',
      startDate: scheduledTime,
      endDate: scheduledTime.add(const Duration(minutes: 15)),
      allDay: false,
      androidParams: const AndroidParams(
        emailInvites: [],
      ),
    );
    Add2Calendar.addEvent2Cal(event);
  }
}
