import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/data/local_store.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/notifications/local_notification_scheduler.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../reminders/application/reminder_service.dart';
import '../application/alarm_launcher.dart';
import '../application/alarm_session_service.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_session.dart';

/// Drives the wake-up alarm screen and the quiz screen.
///
/// The alarm itself (sound + vibration) is the OS-owned insistent notification,
/// so navigating between screens, rebuilds and backgrounding never affect it.
/// It is stopped in exactly one place: [_completeAlarm], after the last quiz
/// question has been answered correctly.
class AlarmController extends GetxController {
  AlarmController({
    required FlutterLocalNotificationsPlugin notificationPlugin,
    required ReminderService reminderService,
  })  : _plugin = notificationPlugin,
        _reminderService = reminderService;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderService _reminderService;
  final AlarmSessionService _service = AlarmSessionService.instance;

  static const _log = AppLogger('Alarm');

  final currentTimeString = ''.obs;
  final currentDateString = ''.obs;
  final alarmTimeString = ''.obs;

  final questionIndex = 0.obs;
  final selectedOption = RxnInt();
  final showWrong = false.obs;
  final completed = false.obs;

  ReminderPayload? payload;
  Timer? _clockTimer;
  Timer? _wrongTimer;
  bool _busy = false;

  QuizSession? get quiz => _service.quiz;
  QuizQuestion? get currentQuestion => completed.value ? null : quiz?.current;
  int get totalQuestions => quiz?.total ?? 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ReminderPayload) payload = args;
    questionIndex.value = quiz?.currentIndex ?? 0;
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    alarmTimeString.value =
        _localizeDigits(DateFormat('hh:mm a').format(payload?.scheduledTime ?? DateTime.now()));
  }

  bool get _isBangla =>
      Get.isRegistered<LocaleController>() &&
      Get.find<LocaleController>().isBangla;

  String _localizeDigits(String s) {
    if (!_isBangla) return s;
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return s.split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? bn[d] : c;
    }).join();
  }

  void _updateClock() {
    final now = DateTime.now();
    currentTimeString.value =
        _localizeDigits(DateFormat('hh:mm:ss a').format(now));
    currentDateString.value = DateFormat('EEEE, MMMM d').format(now);
  }

  /// Opens the quiz. The alarm keeps ringing — nothing is stopped here.
  void openQuiz() {
    if (quiz == null || completed.value) return;
    if (Get.currentRoute != AppRoutes.quiz) Get.toNamed(AppRoutes.quiz);
  }

  Future<void> answer(int optionIndex) async {
    final q = quiz;
    if (q == null || completed.value || _busy) return;
    _busy = true;
    try {
      selectedOption.value = optionIndex;
      switch (q.submit(optionIndex)) {
        case QuizAnswerResult.wrong:
          showWrong.value = true;
          _wrongTimer?.cancel();
          _wrongTimer = Timer(const Duration(milliseconds: 1200), () {
            showWrong.value = false;
            selectedOption.value = null;
          });
        case QuizAnswerResult.correct:
          showWrong.value = false;
          await Future<void>.delayed(const Duration(milliseconds: 350));
          selectedOption.value = null;
          questionIndex.value = q.currentIndex;
        case QuizAnswerResult.completed:
          showWrong.value = false;
          await _completeAlarm();
      }
    } finally {
      _busy = false;
    }
  }

  /// Stops the alarm. Guarded so audio, vibration and the notification are
  /// stopped exactly once.
  Future<void> _completeAlarm() async {
    if (!_service.tryFinish()) return;
    completed.value = true;

    await _cancelRingingNotification();

    try {
      await LocalStore.instance.init();
      final scheduled = payload?.scheduledTime ?? DateTime.now();
      final log = ReminderLog(
        id: 'log_${LocalNotificationScheduler.wakeReminderId}_'
            '${scheduled.millisecondsSinceEpoch}',
        reminderId: LocalNotificationScheduler.wakeReminderId,
        type: ReminderType.sleep,
        scheduledTime: scheduled,
        firedAt: scheduled,
        confirmedAt: DateTime.now(),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      );
      await LocalStore.instance.logs.put(log.id, log.toMap());
    } catch (e) {
      _log.e('Failed to write alarm completion log: $e');
    }

    try {
      await _reminderService.refreshSchedule();
    } catch (e) {
      _log.e('Failed to refresh schedule after alarm: $e');
    }

    await Future<void>.delayed(const Duration(milliseconds: 2200));
    _service.reset();
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _cancelRingingNotification() async {
    try {
      var ringing = await AlarmLauncher.ringingAlarm(_plugin);
      while (ringing != null) {
        await _plugin.cancel(ringing.id);
        final next = await AlarmLauncher.ringingAlarm(_plugin);
        if (next?.id == ringing.id) break;
        ringing = next;
      }
    } catch (e) {
      _log.e('Failed to cancel alarm notification: $e');
    }
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _wrongTimer?.cancel();
    super.onClose();
  }
}
