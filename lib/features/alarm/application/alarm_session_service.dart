import '../domain/quiz_session.dart';
import 'quiz_service.dart';

/// Holds the state of the one ringing wake-up alarm so it survives route
/// changes, controller rebuilds and the app going to the background.
///
/// The ringing itself is owned by the OS notification (insistent alarm
/// channel), not by any screen, so opening/closing the quiz never touches it.
class AlarmSessionService {
  AlarmSessionService._(this._quiz);

  static final AlarmSessionService instance =
      AlarmSessionService._(QuizService(history: HiveQuizHistoryStore()));

  AlarmSessionService.forTest(QuizService quiz) : _quiz = quiz;

  final QuizService _quiz;

  QuizSession? _session;
  String? _activeKey;
  bool _active = false;
  final Set<String> _completedKeys = {};

  bool get isActive => _active;
  QuizSession? get quiz => _session;

  static String keyFor(DateTime? scheduledTime) =>
      scheduledTime == null
          ? 'unknown'
          : scheduledTime.millisecondsSinceEpoch.toString();

  /// Starts a session for the alarm scheduled at [scheduledTime]. Returns false
  /// (and changes nothing) when a session is already active or this occurrence
  /// was already completed.
  Future<bool> begin(DateTime? scheduledTime) async {
    if (_active) return false;
    final key = keyFor(scheduledTime);
    if (_completedKeys.contains(key)) return false;
    _active = true;
    _activeKey = key;
    _session = await _quiz.createSession();
    return true;
  }

  /// Marks the session finished. Returns true only for the first call, so the
  /// audio/vibration/notification are stopped exactly once.
  bool tryFinish() {
    if (!_active) return false;
    _active = false;
    if (_activeKey != null) _completedKeys.add(_activeKey!);
    _activeKey = null;
    return true;
  }

  /// Clears the finished quiz once the completion screen has been left.
  void reset() {
    if (!_active) _session = null;
  }
}
