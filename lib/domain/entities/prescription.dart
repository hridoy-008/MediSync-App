import 'package:equatable/equatable.dart';

import '../enum_codec.dart';
import '../enums.dart';

/// A captured prescription plus the structured items extracted from it.
class Prescription extends Equatable {
  const Prescription({
    required this.id,
    required this.capturedAt,
    this.imagePath,
    this.remoteImageUrl,
    this.rawText = '',
    this.localeCode = 'en',
    this.script = PrescriptionScript.unknown,
    this.source = PrescriptionSource.camera,
    this.ocrEngine = OcrEngine.onDeviceMlKit,
    this.reviewed = false,
    this.medicines = const [],
    this.tests = const [],
    this.instructions = const [],
  });

  final String id;
  final DateTime capturedAt;
  final String? imagePath; // local file path
  final String? remoteImageUrl; // Firebase Storage URL (after consent)
  final String rawText;
  final String localeCode;
  final PrescriptionScript script;
  final PrescriptionSource source;
  final OcrEngine ocrEngine;

  /// True only after the user confirms on the review screen (PRD P0-2).
  final bool reviewed;

  final List<Medicine> medicines;
  final List<TestItem> tests;
  final List<Instruction> instructions;

  Prescription copyWith({
    String? imagePath,
    String? remoteImageUrl,
    String? rawText,
    String? localeCode,
    PrescriptionScript? script,
    PrescriptionSource? source,
    OcrEngine? ocrEngine,
    bool? reviewed,
    List<Medicine>? medicines,
    List<TestItem>? tests,
    List<Instruction>? instructions,
  }) {
    return Prescription(
      id: id,
      capturedAt: capturedAt,
      imagePath: imagePath ?? this.imagePath,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      rawText: rawText ?? this.rawText,
      localeCode: localeCode ?? this.localeCode,
      script: script ?? this.script,
      source: source ?? this.source,
      ocrEngine: ocrEngine ?? this.ocrEngine,
      reviewed: reviewed ?? this.reviewed,
      medicines: medicines ?? this.medicines,
      tests: tests ?? this.tests,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'capturedAt': capturedAt.toIso8601String(),
        'imagePath': imagePath,
        'remoteImageUrl': remoteImageUrl,
        'rawText': rawText,
        'localeCode': localeCode,
        'script': script.name,
        'source': source.name,
        'ocrEngine': ocrEngine.name,
        'reviewed': reviewed,
        'medicines': medicines.map((e) => e.toMap()).toList(),
        'tests': tests.map((e) => e.toMap()).toList(),
        'instructions': instructions.map((e) => e.toMap()).toList(),
      };

  factory Prescription.fromMap(Map<String, dynamic> m) => Prescription(
        id: m['id'] as String,
        capturedAt: DateTime.parse(m['capturedAt'] as String),
        imagePath: m['imagePath'] as String?,
        remoteImageUrl: m['remoteImageUrl'] as String?,
        rawText: m['rawText'] as String? ?? '',
        localeCode: m['localeCode'] as String? ?? 'en',
        script:
            enumByName(PrescriptionScript.values, m['script'], PrescriptionScript.unknown),
        source:
            enumByName(PrescriptionSource.values, m['source'], PrescriptionSource.camera),
        ocrEngine:
            enumByName(OcrEngine.values, m['ocrEngine'], OcrEngine.onDeviceMlKit),
        reviewed: m['reviewed'] as bool? ?? false,
        medicines: (m['medicines'] as List?)
                ?.map((e) => Medicine.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        tests: (m['tests'] as List?)
                ?.map((e) => TestItem.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        instructions: (m['instructions'] as List?)
                ?.map((e) =>
                    Instruction.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [id, capturedAt, reviewed, medicines, tests];
}

class Medicine extends Equatable {
  const Medicine({
    required this.id,
    required this.name,
    this.dose = '',
    this.frequencyPerDay = 1,
    this.timing = FoodTiming.anyTime,
    this.durationDays,
    this.notes = '',
    this.confidence = const {},
    this.stockCount,
    this.lowStockThreshold,
    this.stockAlertEnabled = false,
  });

  final String id;
  final String name;
  final String dose; // e.g. "500 mg", "1 tablet"
  final int frequencyPerDay;
  final FoodTiming timing;
  final int? durationDays;
  final String notes;

  // Stock inventory fields
  final int? stockCount;
  final int? lowStockThreshold;
  final bool stockAlertEnabled;

  /// field name -> confidence, e.g. {'name': low, 'dose': high}.
  final Map<String, FieldConfidence> confidence;

  bool get hasLowConfidence =>
      confidence.values.any((c) => c == FieldConfidence.low);

  Medicine copyWith({
    String? name,
    String? dose,
    int? frequencyPerDay,
    FoodTiming? timing,
    int? durationDays,
    String? notes,
    Map<String, FieldConfidence>? confidence,
    int? stockCount,
    int? lowStockThreshold,
    bool? stockAlertEnabled,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
      timing: timing ?? this.timing,
      durationDays: durationDays ?? this.durationDays,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      stockCount: stockCount ?? this.stockCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      stockAlertEnabled: stockAlertEnabled ?? this.stockAlertEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dose': dose,
        'frequencyPerDay': frequencyPerDay,
        'timing': timing.name,
        'durationDays': durationDays,
        'notes': notes,
        'confidence': confidence.map((k, v) => MapEntry(k, v.name)),
        'stockCount': stockCount,
        'lowStockThreshold': lowStockThreshold,
        'stockAlertEnabled': stockAlertEnabled,
      };

  factory Medicine.fromMap(Map<String, dynamic> m) => Medicine(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        dose: m['dose'] as String? ?? '',
        frequencyPerDay: (m['frequencyPerDay'] as num?)?.toInt() ?? 1,
        timing: enumByName(FoodTiming.values, m['timing'], FoodTiming.anyTime),
        durationDays: (m['durationDays'] as num?)?.toInt(),
        notes: m['notes'] as String? ?? '',
        confidence: (m['confidence'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                enumByName(FieldConfidence.values, v, FieldConfidence.high),
              ),
            ) ??
            const {},
        stockCount: m['stockCount'] as int?,
        lowStockThreshold: m['lowStockThreshold'] as int?,
        stockAlertEnabled: m['stockAlertEnabled'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        dose,
        frequencyPerDay,
        timing,
        durationDays,
        notes,
        stockCount,
        lowStockThreshold,
        stockAlertEnabled,
      ];
}

class TestItem extends Equatable {
  const TestItem({
    required this.id,
    required this.name,
    this.instructions = '',
    this.confidence = const {},
  });

  final String id;
  final String name;
  final String instructions;
  final Map<String, FieldConfidence> confidence;

  bool get hasLowConfidence =>
      confidence.values.any((c) => c == FieldConfidence.low);

  TestItem copyWith({String? name, String? instructions}) => TestItem(
        id: id,
        name: name ?? this.name,
        instructions: instructions ?? this.instructions,
        confidence: confidence,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'instructions': instructions,
        'confidence': confidence.map((k, v) => MapEntry(k, v.name)),
      };

  factory TestItem.fromMap(Map<String, dynamic> m) => TestItem(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        instructions: m['instructions'] as String? ?? '',
        confidence: (m['confidence'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                enumByName(FieldConfidence.values, v, FieldConfidence.high),
              ),
            ) ??
            const {},
      );

  @override
  List<Object?> get props => [id, name, instructions];
}

class Instruction extends Equatable {
  const Instruction({required this.id, required this.text});

  final String id;
  final String text;

  Instruction copyWith({String? text}) =>
      Instruction(id: id, text: text ?? this.text);

  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  factory Instruction.fromMap(Map<String, dynamic> m) =>
      Instruction(id: m['id'] as String, text: m['text'] as String? ?? '');

  @override
  List<Object?> get props => [id, text];
}
