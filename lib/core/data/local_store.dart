import 'package:hive_flutter/hive_flutter.dart';

/// Opens and exposes the Hive boxes that hold the offline source of truth —
/// most importantly the **reminder mirror** the alarm engine reads (TRD §6).
///
/// Records are stored as plain `Map` (via each entity's `toMap`/`fromMap`) so we
/// avoid generated type adapters and keep the schema flexible.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const boxPrescriptions = 'box.prescriptions';
  static const boxReminders = 'box.reminders';
  static const boxLogs = 'box.logs';
  static const boxMeals = 'box.meals';
  static const boxSingletons = 'box.singletons'; // profile, hydration, sleep

  late Box<Map> prescriptions;
  late Box<Map> reminders;
  late Box<Map> logs;
  late Box<Map> meals;
  late Box<Map> singletons;

  bool _ready = false;
  bool get isReady => _ready;

  /// Must be called before any repository use. Safe to call from the boot
  /// receiver isolate (no Firebase needed).
  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    prescriptions = await Hive.openBox<Map>(boxPrescriptions);
    reminders = await Hive.openBox<Map>(boxReminders);
    logs = await Hive.openBox<Map>(boxLogs);
    meals = await Hive.openBox<Map>(boxMeals);
    singletons = await Hive.openBox<Map>(boxSingletons);
    _ready = true;
  }

  /// Hive returns `Map<dynamic,dynamic>`; normalize to `Map<String,dynamic>`.
  static Map<String, dynamic> normalize(Map raw) =>
      raw.map((k, v) => MapEntry(k.toString(), v));
}
