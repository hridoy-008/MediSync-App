import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
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
import '../../reminders/application/reminder_service.dart';

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
    final confirmed = d.copyWith(reviewed: true);
    await _repo.save(confirmed);
    final preview = await _reminderService.previewForPrescription(confirmed);
    draft.value = confirmed;
    previewReminders.assignAll(preview);
    Get.toNamed(AppRoutes.schedulePreview);
  }

  /// Adjust one daily fire time for a previewed reminder before committing.
  void updatePreviewTime(int reminderIndex, int timeIndex, int minutes) {
    if (reminderIndex < 0 || reminderIndex >= previewReminders.length) return;
    final r = previewReminders[reminderIndex];
    final times = [...r.recurrence.timesOfDay];
    if (timeIndex < 0 || timeIndex >= times.length) return;
    times[timeIndex] = minutes;
    times.sort();
    previewReminders[reminderIndex] = r.copyWith(
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
    await _reminderService.commitReminders(previewReminders.toList());
    Get.offNamedUntil(AppRoutes.home, (route) => false);
  }
}
