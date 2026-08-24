import 'bangla_numerals.dart';

/// Locale-aware time formatting (TRD §7). Renders Bangla numerals in bn.
class TimeFormat {
  static String hm(int hour, int minute, {required bool bangla}) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    final mm = minute.toString().padLeft(2, '0');
    if (bangla) {
      return '${BanglaNumerals.toBangla(h)}:${_bnPad(minute)} ${hour < 12 ? 'AM' : 'PM'}';
    }
    return '$h:$mm $ampm';
  }

  static String fromDateTime(DateTime t, {required bool bangla}) =>
      hm(t.hour, t.minute, bangla: bangla);

  static String fromMinutes(int minutesFromMidnight, {required bool bangla}) =>
      hm(minutesFromMidnight ~/ 60, minutesFromMidnight % 60, bangla: bangla);

  static String formatDate(DateTime dt, {required bool isBangla}) {
    final year = dt.year;
    final month = dt.month;
    final day = dt.day;
    final monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthsBn = [
      'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
    ];
    final mStr = isBangla ? monthsBn[month - 1] : monthsEn[month - 1];
    if (isBangla) {
      final dayBn = BanglaNumerals.toBangla(day);
      final yearBn = BanglaNumerals.toBangla(year);
      return '$dayBn $mStr $yearBn';
    }
    return '$day $mStr $year';
  }

  static String _bnPad(int minute) {
    final mm = minute.toString().padLeft(2, '0');
    return BanglaNumerals.toBangla(int.parse(mm)).padLeft(2, '০');
  }
}
