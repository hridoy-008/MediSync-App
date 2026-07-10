import '../../domain/entities/prescription.dart';

class StructuredResult {
  const StructuredResult({
    this.medicines = const [],
    this.tests = const [],
    this.instructions = const [],
  });
  final List<Medicine> medicines;
  final List<TestItem> tests;
  final List<Instruction> instructions;
}

/// Turns raw OCR text into structured items with per-field confidence (TRD §5).
/// Swappable for an LLM-backed structurer in Cloud Functions (Open Question Q1).
abstract interface class PrescriptionStructurer {
  Future<StructuredResult> structure(String rawText);
}
