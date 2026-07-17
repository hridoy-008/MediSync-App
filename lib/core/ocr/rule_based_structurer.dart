import 'package:uuid/uuid.dart';

import '../../domain/entities/prescription.dart';
import '../../domain/enums.dart';
import '../utils/bangla_numerals.dart';
import 'prescription_structurer.dart';

/// Heuristic, on-device structurer (TRD §5 stub for the LLM step). It is
/// deliberately conservative: anything it isn't sure about is flagged
/// low-confidence so the mandatory review screen draws the user's eye to it.
class RuleBasedStructurer implements PrescriptionStructurer {
  const RuleBasedStructurer();
  static final _uuid = Uuid();

  // Matches leading line numbers (e.g. "1.", "1)", "(1)", "১.", "১)"), bullets (•, *, -, ·), and Rx/Rx:
  static final _listPrefix = RegExp(
    r'^([•·\-\*\+]+|\d+[\.\)]|\(\d+\)|[০-৯]+[\.\)]|\([০-৯]+\)|rx:?)\s*',
    caseSensitive: false,
  );

  // Lines that look like a medicine (including common OCR typos of tab/cap/syp).
  static final _medPrefix = RegExp(
      r'^(tablet|capsule|syrup|tab|cap|syp|inj|susp|t|tot|tod|tob|cop|cyp|cab|tad)(?:\.?(?:\s+|$))',
      caseSensitive: false);

  static final _medPrefixBn = RegExp(
      r'^(ট্যাবলেট|ক্যাপসুল|সিরাপ|ইনজেকশন|ট্যাব|ক্যাপ|ইনজ)(?:\.?(?:\s+|$))',
      caseSensitive: false);

  static final _dose = RegExp(
      r'([\d০-৯]+(\.[\d০-৯]+)?)\s?(mg|ml|mcg|g|iu|tablet|tab|মি\.?গ্রা\.?|এমজি|মি\.?লি\.?|এমএল|টি|চামচ)',
      caseSensitive: false);

  // Dosing patterns: 1+0+1, 1-0-1, 1 0 1
  static final _tripleDose = RegExp(r'([\d০-৯])\s*[+\-x ]\s*([\d০-৯])\s*[+\-x ]\s*([\d০-৯])');
  static final _testHint = RegExp(
      r'\b(cbc|x-?ray|usg|ultrasound|ecg|mri|ct|test|fbs|2hbs|hba1c|lipid|urine|s\.?creatinine)\b',
      caseSensitive: false);

  static final _freqCodes = RegExp(
    r'\b(bd|bid|tds|tid|od|once|qid|daily|times)\b',
    caseSensitive: false,
  );

  static final _freqCodesBn = RegExp(
    r'(বার|করে|প্রতিদিন|দৈনিক)(?:\s+|$)',
    caseSensitive: false,
  );

  @override
  Future<StructuredResult> structure(String rawText) async {
    final medicines = <Medicine>[];
    final tests = <TestItem>[];
    final instructions = <Instruction>[];

    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .map((l) {
          var cleaned = l;
          while (true) {
            final next = cleaned.replaceFirst(_listPrefix, '').trim();
            if (next == cleaned) break;
            cleaned = next;
          }
          return cleaned;
        })
        .where((l) => l.length > 1)
        .toList();

    final consolidatedLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final current = lines[i];
      final normalized = BanglaNumerals.toWestern(current);
      
      final isTripleDoseOnly = _tripleDose.hasMatch(normalized) && 
          !RegExp(r'[a-zA-Z\u0980-\u09FF]{5,}').hasMatch(
              normalized.replaceAll(RegExp(r'\b(tab|cap|syp|inj|before|after|food|meal)\b', caseSensitive: false), '')
          );

      final isDoseOnlyOrInstruction = RegExp(r'^[\d\s+\-x•·/]+$').hasMatch(normalized) ||
          (RegExp(r'^\d').hasMatch(normalized) && 
           !RegExp(r'\b[a-zA-Z\u0980-\u09FF]{5,}\b').hasMatch(
             normalized.toLowerCase()
               .replaceAll(RegExp(r'\b(tablet|capsule|spoon|after|before|food|meal|water|daily|times|খাবার|আগে|পরে|খালি|পেটে|টি|চামচ|একবার|দুইবার|তিনবার)\b'), '')
           ));

      if ((isTripleDoseOnly || isDoseOnlyOrInstruction) && consolidatedLines.isNotEmpty) {
        final prevNormalized = BanglaNumerals.toWestern(consolidatedLines.last);
        if (!_testHint.hasMatch(prevNormalized)) {
          final hasTripleDoseAlready = _tripleDose.hasMatch(prevNormalized);
          if (!isTripleDoseOnly || !hasTripleDoseAlready) {
            consolidatedLines[consolidatedLines.length - 1] = '${consolidatedLines.last} $current';
            continue;
          }
        }
      }
      consolidatedLines.add(current);
    }

    for (final line in consolidatedLines) {
      final normalized = BanglaNumerals.toWestern(line);

      if (_testHint.hasMatch(normalized)) {
        tests.add(TestItem(
          id: _uuid.v4(),
          name: line,
          confidence: {'name': FieldConfidence.medium},
        ));
        continue;
      }

      if (_looksLikeMedicine(normalized)) {
        medicines.add(_parseMedicine(line, normalized));
        continue;
      }

      // Otherwise treat as a free-text instruction (low signal).
      if (line.length > 3) {
        instructions.add(Instruction(id: _uuid.v4(), text: line));
      }
    }

    return StructuredResult(
      medicines: medicines,
      tests: tests,
      instructions: instructions,
    );
  }

  bool _looksLikeMedicine(String normalized) =>
      _medPrefix.hasMatch(normalized) ||
      _medPrefixBn.hasMatch(normalized) ||
      _dose.hasMatch(normalized) ||
      _tripleDose.hasMatch(normalized);

  Medicine _parseMedicine(String original, String normalized) {
    final confidence = <String, FieldConfidence>{};

    // Name = strip the prefix + dosing tail + frequency terms.
    var name = original
        .replaceAll(_medPrefix, '')
        .replaceAll(_medPrefixBn, '')
        .replaceAll(_tripleDose, '')
        .replaceAll(_freqCodes, '')
        .replaceAll(_freqCodesBn, '')
        .trim();

    final doseMatch = _dose.firstMatch(original);
    final doseOriginal = doseMatch?.group(0) ?? '';
    final dose = BanglaNumerals.toWestern(doseOriginal);

    if (doseOriginal.isNotEmpty) {
      name = name.replaceAll(RegExp(RegExp.escape(doseOriginal), caseSensitive: false), '').trim();
    }
    name = name.replaceAll(RegExp(r'[-•·]+$'), '').trim();

    // Check if name is purely junk or empty
    final isJunkName = name.isEmpty ||
        RegExp(r'^[\d\s+\-x•·/()]+$').hasMatch(name) ||
        name.toLowerCase() == 'tab' ||
        name.toLowerCase() == 'tablet' ||
        name.toLowerCase() == 'tot' ||
        name.toLowerCase() == 'cap' ||
        name.toLowerCase() == 'capsule' ||
        name.toLowerCase() == 'syp' ||
        name.toLowerCase() == 'syrup' ||
        name.toLowerCase() == 'inj';

    if (isJunkName) {
      name = '';
      confidence['name'] = FieldConfidence.low;
    } else {
      confidence['name'] =
          (_medPrefix.hasMatch(original) || _medPrefixBn.hasMatch(original))
              ? FieldConfidence.high
              : FieldConfidence.medium;
    }
    confidence['dose'] = dose.isEmpty ? FieldConfidence.low : FieldConfidence.high;

    // Frequency from triple-dose (sum of the three slots) or explicit codes.
    var frequency = 1;
    final triple = _tripleDose.firstMatch(original);
    if (triple != null) {
      frequency = [triple.group(1), triple.group(2), triple.group(3)]
          .map((g) => BanglaNumerals.toWestern(g ?? '0'))
          .map((g) => int.tryParse(g) ?? 0)
          .fold(0, (a, b) => a + b)
          .clamp(1, 6);
      confidence['frequency'] = FieldConfidence.high;
    } else {
      frequency = _frequencyFromCodes(normalized);
      confidence['frequency'] =
          frequency > 0 ? FieldConfidence.medium : FieldConfidence.low;
      if (frequency == 0) frequency = 1;
    }

    final timing = _timingFrom(original, normalized);
    confidence['timing'] =
        timing == FoodTiming.anyTime ? FieldConfidence.low : FieldConfidence.medium;

    return Medicine(
      id: _uuid.v4(),
      name: name,
      dose: dose,
      frequencyPerDay: frequency,
      timing: timing,
      confidence: confidence,
    );
  }

  int _frequencyFromCodes(String normalized) {
    final lower = normalized.toLowerCase();
    if (RegExp(r'\b(tds|tid)\b').hasMatch(lower)) return 3;
    if (RegExp(r'\b(bd|bid)\b').hasMatch(lower)) return 2;
    if (RegExp(r'\b(od|once)\b').hasMatch(lower)) return 1;
    if (RegExp(r'\b(qid)\b').hasMatch(lower)) return 4;
    final perDay = BanglaNumerals.firstInt(normalized);
    if (lower.contains('বার') && perDay != null) return perDay.clamp(1, 6);
    return 0;
  }

  FoodTiming _timingFrom(String original, String normalized) {
    final s = '${original.toLowerCase()} $normalized';
    if (s.contains('before food') ||
        s.contains('empty stomach') ||
        original.contains('খাবারের আগে') ||
        original.contains('খালি পেটে')) {
      return FoodTiming.beforeFood;
    }
    if (s.contains('after food') ||
        s.contains('after meal') ||
        original.contains('খাবারের পরে')) {
      return FoodTiming.afterFood;
    }
    if (s.contains('with food') || original.contains('খাবারের সাথে')) {
      return FoodTiming.withFood;
    }
    return FoodTiming.anyTime;
  }
}
