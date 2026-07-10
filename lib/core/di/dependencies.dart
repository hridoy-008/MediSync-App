import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../features/reminders/application/reminder_service.dart';
import '../data/local_store.dart';
import '../data/preference_store.dart';
import '../data/repositories/config_repository_impl.dart';
import '../data/repositories/prescription_repository_impl.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../data/repositories/reminder_repository_impl.dart';
import '../auth/firebase_auth_repository.dart';
import '../firebase/firebase_service.dart';
import '../firebase/remote_mirror.dart';
import '../localization/locale_controller.dart';
import '../notifications/reminder_scheduler.dart';
import '../ocr/cloud_ocr_service.dart';
import '../ocr/mlkit_ocr_service.dart';
import '../ocr/prescription_structurer.dart';
import '../ocr/rule_based_structurer.dart';
import '../ocr/script_detector.dart';
import '../permissions/permission_service.dart';

/// Wires the object graph with GetX. The async-initialized singletons (prefs,
/// notification plugin, scheduler) are created in main() and passed in.
void registerDependencies({
  required PreferenceStore prefs,
  required FlutterLocalNotificationsPlugin plugin,
  required ReminderScheduler scheduler,
}) {
  final firebase = FirebaseService.instance;
  final mirror = RemoteMirror(firebase);
  final store = LocalStore.instance;

  Get
    ..put<PreferenceStore>(prefs, permanent: true)
    ..put<FirebaseService>(firebase, permanent: true)
    ..put<RemoteMirror>(mirror, permanent: true)
    ..put<FlutterLocalNotificationsPlugin>(plugin, permanent: true)
    ..put<ReminderScheduler>(scheduler, permanent: true);

  // Repositories
  final reminderRepo = ReminderRepositoryImpl(store, mirror);
  final configRepo = ConfigRepositoryImpl(store, mirror);
  Get
    ..put<PrescriptionRepository>(
        PrescriptionRepositoryImpl(store, mirror), permanent: true)
    ..put<ReminderRepository>(reminderRepo, permanent: true)
    ..put<ConfigRepository>(configRepo, permanent: true)
    ..put<ProfileRepository>(ProfileRepositoryImpl(store, mirror),
        permanent: true)
    ..put<AuthRepository>(FirebaseAuthRepository(firebase), permanent: true);

  // OCR
  const detector = ScriptDetector();
  Get
    ..put<MlKitOcrService>(MlKitOcrService(detector: detector), permanent: true)
    ..put<CloudOcrService>(CloudOcrService(firebase, detector: detector),
        permanent: true)
    ..put<PrescriptionStructurer>(const RuleBasedStructurer(), permanent: true);

  // Application services
  Get
    ..put<ReminderService>(
      ReminderService(
        repository: reminderRepo,
        configRepository: configRepo,
        scheduler: scheduler,
      ),
      permanent: true,
    )
    ..put<PermissionService>(PermissionService(plugin), permanent: true)
    ..put<LocaleController>(LocaleController(prefs), permanent: true);
}
