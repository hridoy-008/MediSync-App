import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/enums.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'ocr_service.dart';
import 'script_detector.dart';

/// On-device ML Kit OCR — fast, offline English/Latin path (TRD §2, §5).
/// (ML Kit's Latin recognizer does not read Bengali script; the router sends
/// Bangla/mixed images to the cloud service instead.)
class MlKitOcrService implements OcrService {
  MlKitOcrService({ScriptDetector? detector})
      : _detector = detector ?? const ScriptDetector();
  final ScriptDetector _detector;
  static const _log = AppLogger('MlKitOcr');

  @override
  bool get worksOffline => true;

  @override
  Future<Result<OcrResult>> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final text = recognized.text;
      return Success(OcrResult(
        rawText: text,
        engine: OcrEngine.onDeviceMlKit,
        script: _detector.detect(text),
      ));
    } catch (e) {
      _log.e('ML Kit recognize failed', e);
      return Err(Failure('Could not read the image.', cause: e));
    } finally {
      await recognizer.close();
    }
  }
}
