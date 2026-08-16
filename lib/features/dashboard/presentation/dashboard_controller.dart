import 'package:get/get.dart';

import '../../../domain/entities/reminder.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/domain/timeline_builder.dart';
import '../../reminders/domain/timeline_item.dart';

class DashboardController extends GetxController {
  DashboardController({
    required ReminderRepository reminderRepository,
    required ProfileRepository profileRepository,
    required ReminderService reminderService,
    ConfigRepository? configRepository,
    TimelineBuilder builder = const TimelineBuilder(),
  })  : _reminders = reminderRepository,
        _profiles = profileRepository,
        _service = reminderService,
        _config = configRepository ?? Get.find<ConfigRepository>(),
        _builder = builder;

  final ReminderRepository _reminders;
  final ProfileRepository _profiles;
  final ReminderService _service;
  final ConfigRepository _config;
  final TimelineBuilder _builder;

  final navIndex = 0.obs;
  final loading = true.obs;
  final timeline = <TimelineItem>[].obs;
  final profile = const UserProfile(id: 'me').obs;
  final doneCount = 0.obs;
  final totalCount = 0.obs;
  final Rxn<TimelineItem> nextUp = Rxn<TimelineItem>();
  final logs = <ReminderLog>[].obs;

  @override
  void onInit() {
    super.onInit();
    _profiles.watch().listen(profile.call);
    // Rebuild whenever reminders or logs change.
    _reminders.watchAll().listen((_) => loadToday());
    _reminders.watchLogs().listen((_) => loadToday());
    loadToday();
  }

  void setTab(int i) => navIndex.value = i;

  Future<void> loadToday() async {
    final reminders = (await _reminders.getAll()).valueOrNull ?? const [];
    final allLogs = (await _reminders.getLogs()).valueOrNull ?? const [];
    final meals = (await _config.getMeals()).valueOrNull ?? const [];
    logs.assignAll(allLogs);
    final items = _builder.buildForDay(
      reminders: reminders,
      logs: allLogs,
      day: DateTime.now(),
      meals: meals,
    );
    timeline.assignAll(items);
    final a = _builder.adherence(items);
    doneCount.value = a.done;
    totalCount.value = a.total;
    nextUp.value = _builder.nextUp(items, DateTime.now());
    loading.value = false;
  }

  Future<void> act(TimelineItem item, ReminderAction action) async {
    await _service.logAction(
      reminder: item.reminder,
      scheduledTime: item.scheduledTime,
      action: action,
    );
    await loadToday();
  }

  /// Called on app open (and from the foreground notification callback).
  Future<void> onResume() async {
    await _service.refreshSchedule();
    await loadToday();
  }
}
