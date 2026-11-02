import 'package:equatable/equatable.dart';

import '../../../core/utils/bangla_numerals.dart';
import '../../../domain/enums.dart';

/// A prescription dosage pattern such as `1+0+1`: doses at breakfast, lunch
/// and dinner. Pure parsing — never guesses; anything ambiguous is `null`.
class DosePattern extends Equatable {
  const DosePattern(this.breakfast, this.lunch, this.dinner);

  final int breakfast;
  final int lunch;
  final int dinner;

  /// Three single digits separated by `+`, `-`, `x`/`×` or whitespace. Digits
  /// may be Bangla. Not allowed to be part of a longer number (`10+0+1`).
  static final regex = RegExp(
    r'(?<![\d০-৯])([\d০-৯])\s*(?:[+\-x×]|\s)\s*([\d০-৯])\s*(?:[+\-x×]|\s)\s*([\d০-৯])(?![\d০-৯])',
  );

  static DosePattern? tryParse(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = regex.firstMatch(BanglaNumerals.toWestern(text));
    if (match == null) return null;
    final b = int.parse(match.group(1)!);
    final l = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    if (b == 0 && l == 0 && d == 0) return null;
    return DosePattern(b, l, d);
  }

  /// Canonical text, e.g. `1+0+1`.
  String get normalized => '$breakfast+$lunch+$dinner';

  int get dosesPerDay =>
      (breakfast > 0 ? 1 : 0) + (lunch > 0 ? 1 : 0) + (dinner > 0 ? 1 : 0);

  /// Doses at each meal with a non-zero count, in day order.
  List<({MealType meal, int count})> get slots => [
        if (breakfast > 0) (meal: MealType.breakfast, count: breakfast),
        if (lunch > 0) (meal: MealType.lunch, count: lunch),
        if (dinner > 0) (meal: MealType.dinner, count: dinner),
      ];

  @override
  List<Object?> get props => [breakfast, lunch, dinner];
}
