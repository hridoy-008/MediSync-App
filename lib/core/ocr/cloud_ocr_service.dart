import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart' hide Result;

import '../../domain/enums.dart';
import '../firebase/firebase_service.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'ocr_service.dart';
import 'script_detector.dart';

/// Cloud Vision OCR via the `extractPrescription` Cloud Function (TRD §5, §8).
///
/// STUB: the callable isn't deployed yet. When Firebase is unavailable or the
/// function is missing, this returns a network failure so the router falls back
/// to the on-device path and lets the user enter Bangla fields manually
/// (TRD §5 "offline fallback ... never blocks").
class CloudOcrService implements OcrService {
  CloudOcrService(this._firebase, {ScriptDetector? detector})
      : _detector = detector ?? const ScriptDetector();
  final FirebaseService _firebase;
  final ScriptDetector _detector;
  static const _log = AppLogger('CloudOcr');

  @override
  bool get worksOffline => false;

  @override
  Future<Result<OcrResult>> recognize(String imagePath) async {
    if (!_firebase.isAvailable) {
      return Err(Failure.network('Cloud OCR needs Firebase + internet.'));
    }
    try {
      final bytes = await File(imagePath).readAsBytes();
      final callable =
          FirebaseFunctions.instance.httpsCallable('extractPrescription');
      final res = await callable.call<Map<String, dynamic>>({
        'imageBase64': base64Encode(bytes),
        'wantStructured': false,
      });
      final text = res.data['rawText'] as String? ?? '';
      return Success(OcrResult(
        rawText: text,
        engine: OcrEngine.cloudVision,
        script: _detector.detect(text),
      ));
    } catch (e) {
      _log.w('Cloud OCR unavailable (stub/not deployed): $e');
      return Err(Failure.network(e));
    }
  }
}
