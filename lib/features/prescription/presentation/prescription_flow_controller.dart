import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/preference_store.dart';
import '../../../core/ocr/cloud_ocr_service.dart';
import '../../../core/ocr/mlkit_ocr_service.dart';
import '../../../core/ocr/ocr_router.dart';
import '../../../core/ocr/prescription_structurer.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/recurrence.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/prescription_repository.dart';
import '../../../core/localization/locale_controller.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/domain/dose_pattern.dart';
import '../../reminders/domain/reminder_generator.dart';

/// Drives the trust-critical capture → extract → review → confirm flow
/// (PRD P0-1, P0-2; Design §5.3). Nothing is scheduled until [confirm].
class PrescriptionFlowController extends GetxController {
  PrescriptionFlowController({
    required PrescriptionRepository repository,
    required ReminderService reminderService,
    required MlKitOcrService onDevice,
    required CloudOcrService cloud,
    required PrescriptionStructurer structurer,
    required PreferenceStore prefs,
    required AppConfig config,
  })  : _repo = repository,
        _reminderService = reminderService,
        _onDevice = onDevice,
        _cloud = cloud,
        _structurer = structurer,
        _prefs = prefs,
        _config = config;

  final PrescriptionRepository _repo;
  final ReminderService _reminderService;
  final MlKitOcrService _onDevice;
  final CloudOcrService _cloud;
  final PrescriptionStructurer _structurer;
  final PreferenceStore _prefs;
  final AppConfig _config;

  final _picker = ImagePicker();
  static final _uuid = Uuid();

  final processing = false.obs;
  final error = RxnString();
  final Rxn<Prescription> draft = Rxn<Prescription>();

  /// Reminders generated from the confirmed draft, shown on the schedule-preview
  /// screen for time adjustment before they're committed + scheduled.
  final previewReminders = <Reminder>[].obs;

  OcrRouter get _router => OcrRouter(
        onDevice: _onDevice,
        cloud: _cloud,
        structurer: _structurer,
        features: _config.features,
        cloudConsentGranted: _prefs.consentCloudOcr,
      );

  /// Pick (camera/gallery) → crop → navigate to processing → extract → review.
  Future<void> capture(PrescriptionSource source) async {
    error.value = null;
    final picked = await _picker.pickImage(
      source: source == PrescriptionSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    Get.toNamed(AppRoutes.processing);
    await _extract(picked.path, source);
  }

  Future<void> _extract(String path, PrescriptionSource source) async {
    processing.value = true;
    error.value = null;
    final res = await _router.extract(
      imagePath: path,
      source: source,
      localeCode: _prefs.localeCode,
    );
    processing.value = false;
    res.fold(
      (prescription) {
        draft.value = prescription;
        Get.offNamed(AppRoutes.review);
      },
      (failure) {
        error.value = failure.message;
      },
    );
  }

  // ---- Review editing (operate on the in-memory draft) ----

  void updateMedicine(int index, Medicine updated) {
    final d = draft.value;
    if (d == null) return;
    final meds = [...d.medicines];
    if (index >= 0 && index < meds.length) {
      meds[index] = updated;
      draft.value = d.copyWith(medicines: meds);
    }
  }

  void removeMedicine(int index) {
    final d = draft.value;
    if (d == null) return;
    final meds = [...d.medicines];
    if (index >= 0 && index < meds.length) {
      meds.removeAt(index);
      draft.value = d.copyWith(medicines: meds);
    }
  }

  void addMedicine() {
    final d = draft.value;
    if (d == null) return;
    final meds = [...d.medicines, Medicine(id: _uuid.v4(), name: '')];
    draft.value = d.copyWith(medicines: meds);
  }

  void updateTest(int index, TestItem updated) {
    final d = draft.value;
    if (d == null) return;
    final tests = [...d.tests];
    if (index >= 0 && index < tests.length) {
      tests[index] = updated;
      draft.value = d.copyWith(tests: tests);
    }
  }

  void updateInstruction(int index, String text) {
    final d = draft.value;
    if (d == null) return;
    final ins = [...d.instructions];
    if (index >= 0 && index < ins.length) {
      ins[index] = ins[index].copyWith(text: text);
      draft.value = d.copyWith(instructions: ins);
    }
  }

  /// P0-2: confirm = the only path to scheduling. Marks reviewed, persists the
  /// prescription, generates a reminder PREVIEW, and routes to the preview
  /// screen (Design §5.3 step 4). Nothing is scheduled yet.
  Future<void> confirm() async {
    final d = draft.value;
    if (d == null) return;

    // Never guess an unclear dosage: the user picks or types it.
    final unclear = unclearIndices(d.medicines);
    if (unclear.isNotEmpty) {
      final i = unclear.first;
      final med = d.medicines[i];
      final bangla = Get.find<LocaleController>().isBangla;
      if (med.name.trim().isEmpty) {
        await _showBlocking(
          title: bangla ? 'ওষুধের নাম দিন' : 'Medicine name needed',
          message: bangla
              ? 'ওষুধ #${i + 1}-এর নাম লিখুন।'
              : 'Enter a name for medicine #${i + 1}.',
        );
        return;
      }
      final picked = await _askDosage(med.name.trim(), bangla);
      if (picked == null) return; // user will type it in the card
      applyPattern(i, picked);
      return confirm(); // continue with the next unclear medicine, if any
    }

    final confirmed = d.copyWith(reviewed: true);

    // Meal-based doses need the user's meal times; don't guess them.
    final missing = await _reminderService.missingMealsFor(confirmed);
    if (missing.isNotEmpty) {
      final bangla = Get.find<LocaleController>().isBangla;
      final names = missing.map((m) => m.name).join(', ');
      await _showBlocking(
        title: bangla ? 'খাবারের সময় সেট করুন' : 'Set your meal times first',
        message: bangla
            ? 'রিমাইন্ডার চালু করার আগে এই খাবারের সময় সেট করুন: $names'
            : 'Reminders need your $names time. Set it before activating the schedule.',
        actionLabel: bangla ? 'খাবারের সময়' : 'Meal times',
        onAction: () => Get.toNamed(AppRoutes.mealConfig),
      );
      return;
    }

    await _repo.save(confirmed);
    final preview = await _reminderService.previewForPrescription(confirmed);
    draft.value = confirmed;
    previewReminders.assignAll(preview);
    Get.toNamed(AppRoutes.schedulePreview);
  }

  /// Bumped when a medicine is changed from outside its editor card, so the
  /// card is rebuilt with the new values.
  final editorRevision = 0.obs;

  /// Sets a dosage chosen by the user (never inferred) on medicine [index].
  void applyPattern(int index, String pattern) {
    final d = draft.value;
    final parsed = DosePattern.tryParse(pattern);
    if (d == null || parsed == null || index < 0 || index >= d.medicines.length) {
      return;
    }
    final m = d.medicines[index];
    updateMedicine(
      index,
      m.copyWith(
        dosePattern: parsed.normalized,
        frequencyPerDay: parsed.dosesPerDay.clamp(1, 6),
        timing: m.timing == FoodTiming.anyTime ? FoodTiming.afterFood : m.timing,
        confidence: {
          ...m.confidence,
          'dosePattern': FieldConfidence.high,
          'frequency': FieldConfidence.high,
          'timing': FieldConfidence.high,
        },
      ),
    );
    editorRevision.value++;
  }

  /// Indices of medicines whose dosage wasn't understood and hasn't been
  /// entered by the user: no readable pattern, an invalid typed pattern, an
  /// unread frequency, or no name.
  List<int> unclearIndices(List<Medicine> meds) {
    const generator = ReminderGenerator();
    final out = <int>[];
    for (var i = 0; i < meds.length; i++) {
      final m = meds[i];
      if (m.name.trim().isEmpty) {
        out.add(i);
        continue;
      }
      if (generator.patternFor(m) != null) continue;
      final typed = m.dosePattern.trim().isNotEmpty;
      final unread = m.confidence['frequency'] == FieldConfidence.low;
      if (typed || unread) out.add(i);
    }
    return out;
  }

  /// Asks which dosage to use. Returns the chosen pattern, or null to type it.
  Future<String?> _askDosage(String name, bool bangla) {
    const options = [
      ('1+0+1', 'Breakfast & Dinner', 'সকাল ও রাত'),
      ('1+1+1', 'Breakfast, Lunch & Dinner', 'সকাল, দুপুর ও রাত'),
      ('1+0+0', 'Breakfast only', 'শুধু সকাল'),
      ('0+1+0', 'Lunch only', 'শুধু দুপুর'),
      ('0+0+1', 'Dinner only', 'শুধু রাত'),
      ('1+1+0', 'Breakfast & Lunch', 'সকাল ও দুপুর'),
      ('0+1+1', 'Lunch & Dinner', 'দুপুর ও রাত'),
    ];
    return Get.dialog<String>(
      AlertDialog(
        title: Text(bangla ? 'ডোজ নির্বাচন করুন' : 'Choose the dosage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(bangla
                  ? '"$name" এর ডোজ স্ক্যান থেকে পড়া যায়নি। প্রেসক্রিপশন দেখে সঠিকটি বেছে নিন:'
                  : 'The dosage for "$name" could not be read from the scan. Pick what your prescription says:'),
              const SizedBox(height: 12),
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back<String>(result: o.$1),
                      child: Text('${o.$1}  ·  ${bangla ? o.$3 : o.$2}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(bangla ? 'নিজে লিখব' : "I'll type it"),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlocking({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('OK')),
          if (actionLabel != null)
            FilledButton(
              onPressed: () {
                Get.back<void>();
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  /// Adjust one daily fire time for a previewed reminder before committing.
  void updatePreviewTime(int reminderIndex, int timeIndex, int minutes) {
    if (reminderIndex < 0 || reminderIndex >= previewReminders.length) return;
    final r = previewReminders[reminderIndex];
    final times = [...r.recurrence.timesOfDay];
    if (timeIndex < 0 || timeIndex >= times.length) return;
    final oldMinutes = times[timeIndex];
    times[timeIndex] = minutes;
    times.sort();
    // Keep the per-meal dose slot attached to its (moved) time.
    final slots = [
      for (final s in r.doseSlots)
        s.minutes == oldMinutes ? s.copyWith(minutes: minutes) : s,
    ];
    previewReminders[reminderIndex] = r.copyWith(
      doseSlots: slots,
      recurrence: RecurrenceRule(
        frequency: r.recurrence.frequency,
        interval: r.recurrence.interval,
        timesOfDay: times,
        weekdays: r.recurrence.weekdays,
        startDate: r.recurrence.startDate,
        endDate: r.recurrence.endDate,
      ),
    );
  }

  /// Commit the previewed reminders + build the OS schedule, then go home.
  Future<void> finalizeSchedule() async {
    await _reminderService.commitReminders(
      previewReminders.toList(),
      replaceRefId: draft.value?.id,
    );
    Get.offNamedUntil(AppRoutes.home, (route) => false);
  }
}
