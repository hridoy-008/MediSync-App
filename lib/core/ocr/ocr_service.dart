import '../../domain/enums.dart';
import '../utils/result.dart';

class OcrResult {
  const OcrResult({
    required this.rawText,
    required this.engine,
    required this.script,
  });
  final String rawText;
  final OcrEngine engine;
  final PrescriptionScript script;
}

/// Vendor-abstracted OCR (TRD §5). ML Kit / Cloud Vision / an LLM-vision model
/// all sit behind this — features never touch a concrete engine.
abstract interface class OcrService {
  /// True if this engine can run without network (used for offline routing).
  bool get worksOffline;

  Future<Result<OcrResult>> recognize(String imagePath);
}
