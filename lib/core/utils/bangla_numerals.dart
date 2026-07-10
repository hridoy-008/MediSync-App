/// Bangla numeral handling (TRD §7) — parse ০-৯ in OCR'd dose/frequency text and
/// render numbers per locale.
class BanglaNumerals {
  static const _bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  /// Convert any Bangla digits in [input] to Western 0-9 (for parsing).
  static String toWestern(String input) {
    final buffer = StringBuffer();
    for (final ch in input.runes) {
      final s = String.fromCharCode(ch);
      final idx = _bn.indexOf(s);
      buffer.write(idx >= 0 ? '$idx' : s);
    }
    return buffer.toString();
  }

  /// Render [number] using Bangla digits (for bn locale display).
  static String toBangla(int number) {
    return number
        .toString()
        .split('')
        .map((d) => int.tryParse(d) != null ? _bn[int.parse(d)] : d)
        .join();
  }

  /// Locale-aware: returns Bangla digits when [isBangla], else Western.
  static String localize(int number, {required bool isBangla}) =>
      isBangla ? toBangla(number) : number.toString();

  /// Extract the first integer from mixed Bangla/Western text (e.g. "৩ বার").
  static int? firstInt(String input) {
    final western = toWestern(input);
    final match = RegExp(r'\d+').firstMatch(western);
    return match == null ? null : int.tryParse(match.group(0)!);
  }
}
