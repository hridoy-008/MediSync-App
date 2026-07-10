import '../../domain/enums.dart';

/// Lightweight Unicode-range script detection for OCR routing (TRD §5, §7).
class ScriptDetector {
  const ScriptDetector();

  /// Bengali block: U+0980–U+09FF.
  bool _isBangla(int cp) => cp >= 0x0980 && cp <= 0x09FF;

  /// Basic Latin letters.
  bool _isLatin(int cp) =>
      (cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A);

  PrescriptionScript detect(String text) {
    var bangla = 0;
    var latin = 0;
    for (final cp in text.runes) {
      if (_isBangla(cp)) bangla++;
      if (_isLatin(cp)) latin++;
    }
    if (bangla == 0 && latin == 0) return PrescriptionScript.unknown;
    if (bangla == 0) return PrescriptionScript.latin;
    if (latin == 0) return PrescriptionScript.bangla;
    // Mixed if the minority script is at least 10% of letters.
    final minority = bangla < latin ? bangla : latin;
    final total = bangla + latin;
    return (minority / total) >= 0.10
        ? PrescriptionScript.mixed
        : (bangla > latin
            ? PrescriptionScript.bangla
            : PrescriptionScript.latin);
  }
}
