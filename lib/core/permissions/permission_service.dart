import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

enum AppPermission { notifications, exactAlarm, camera, batteryOptimization }

/// Wraps the platform permission asks the reminder engine depends on (TRD §6,
/// Design §5.6). Aggressive BD OEM battery managers are surfaced so the user can
/// whitelist the app.
class PermissionService {
  PermissionService(this._notifications);
  final FlutterLocalNotificationsPlugin _notifications;
  static const _log = AppLogger('Permissions');

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> requestNotifications() async {
    final granted = await _android?.requestNotificationsPermission();
    if (granted == null) {
      // iOS
      final ios = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return ios ?? false;
    }
    return granted;
  }

  /// Android 12+ exact-alarm permission (TRD §6, §12).
  Future<bool> requestExactAlarm() async {
    try {
      final granted = await _android?.requestExactAlarmsPermission();
      return granted ?? true; // pre-Android 12 has no such gate
    } catch (e) {
      _log.w('exact-alarm request failed: $e');
      return false;
    }
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Ask to ignore battery optimization — critical on Xiaomi/Oppo/Realme/Samsung.
  Future<bool> requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<Map<AppPermission, bool>> currentStatus() async {
    return {
      AppPermission.notifications:
          await Permission.notification.isGranted,
      AppPermission.camera: await Permission.camera.isGranted,
      AppPermission.batteryOptimization:
          await Permission.ignoreBatteryOptimizations.isGranted,
      // exactAlarm has no reliable read API across versions; treat as best-effort.
      AppPermission.exactAlarm: true,
    };
  }

  Future<void> openSettings() => openAppSettings();
}
