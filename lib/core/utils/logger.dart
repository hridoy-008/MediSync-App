import 'package:flutter/foundation.dart';

/// Minimal tagged logger. Avoids `print` lint and gives one place to route logs
/// to a crash/analytics sink later.
class AppLogger {
  const AppLogger(this.tag);
  final String tag;

  void d(Object? message) => _log('DEBUG', message);
  void i(Object? message) => _log('INFO', message);
  void w(Object? message) => _log('WARN', message);
  void e(Object? message, [Object? error, StackTrace? stack]) {
    _log('ERROR', message);
    if (error != null) debugPrint('[$tag] cause: $error');
    if (stack != null) debugPrint('[$tag] $stack');
  }

  void _log(String level, Object? message) {
    if (kReleaseMode) return;
    debugPrint('[$tag] $level: $message');
  }
}
