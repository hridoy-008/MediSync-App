import 'package:uuid/uuid.dart';

import '../../domain/entities/prescription.dart';
import '../../domain/enums.dart';
import '../config/feature_flags.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'cloud_ocr_service.dart';
import 'mlkit_ocr_service.dart';
import 'ocr_service.dart';
import 'prescription_structurer.dart';

/// Orchestrates the extraction pipeline (TRD §5): on-device first, route
/// Bangla/mixed to cloud when allowed, then structure — always producing an
/// editable draft (never blocks; never schedules — that needs review).
class OcrRouter {
  OcrRouter({
    required MlKitOcrService onDevice,
    required CloudOcrService cloud,
    required PrescriptionStructurer structurer,
    required this.features,
    required this.cloudConsentGranted,
  })  : _onDevice = onDevice,
        _cloud = cloud,
        _structurer = structurer;

  final MlKitOcrService _onDevice;
  final CloudOcrService _cloud;
  final PrescriptionStructurer _structurer;
  final FeatureFlags features;
  final bool cloudConsentGranted;

  static const _log = AppLogger('OcrRouter');
  static final _uuid = Uuid();

  /// Extract an editable, **unconfirmed** prescription draft from an image.
  Future<Result<Prescription>> extract({
    required String imagePath,
    required PrescriptionSource source,
    required String localeCode,
  }) async {
    // 1) Always run the fast on-device pass to get text + detect the script.
    final onDeviceRes = await _onDevice.recognize(imagePath);
    var rawText = onDeviceRes.valueOrNull?.rawText ?? '';
    var engine = OcrEngine.onDeviceMlKit;
    var script = onDeviceRes.valueOrNull?.script ?? PrescriptionScript.unknown;

    // 2) Route Bangla/mixed to cloud when enabled + consented + reachable.
    final needsCloud =
        script == PrescriptionScript.bangla || script == PrescriptionScript.mixed;
    if (needsCloud && features.cloudOcr && cloudConsentGranted) {
      final cloudRes = await _cloud.recognize(imagePath);
      cloudRes.fold(
        (ok) {
          rawText = ok.rawText.isNotEmpty ? ok.rawText : rawText;
          engine = OcrEngine.cloudVision;
          script = ok.script;
        },
        (err) => _log.w('Cloud OCR fell back to on-device text: ${err.message}'),
      );
    }

    // 3) Structure (rule-based stub on-device; LLM later in Cloud Functions).
    final structured = await _structurer.structure(rawText);

    final prescription = Prescription(
      id: _uuid.v4(),
      capturedAt: DateTime.now(),
      imagePath: imagePath,
      rawText: rawText,
      localeCode: localeCode,
      script: script,
      source: source,
      ocrEngine: engine,
      reviewed: false, // P0-2: nothing scheduled until the user confirms
      medicines: structured.medicines,
      tests: structured.tests,
      instructions: structured.instructions,
    );
    return Success(prescription);
  }
}
