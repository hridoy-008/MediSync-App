import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/utils/bangla_numerals.dart';

void main() {
  test('converts Bangla digits to Western for parsing', () {
    expect(BanglaNumerals.toWestern('৩ বার'), '3 বার');
    expect(BanglaNumerals.toWestern('৫০০ mg'), '500 mg');
  });

  test('renders Western to Bangla digits', () {
    expect(BanglaNumerals.toBangla(2025), '২০২৫');
  });

  test('extracts first integer from mixed text', () {
    expect(BanglaNumerals.firstInt('৩ বার'), 3);
    expect(BanglaNumerals.firstInt('take 2 tablets'), 2);
    expect(BanglaNumerals.firstInt('no digits'), isNull);
  });
}
