import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/ocr/script_detector.dart';
import 'package:medisync/domain/enums.dart';

void main() {
  const detector = ScriptDetector();

  test('detects Latin-only text', () {
    expect(detector.detect('Tab Napa 500mg'), PrescriptionScript.latin);
  });

  test('detects Bangla-only text', () {
    expect(detector.detect('নাপা ৫০০ মিলিগ্রাম'), PrescriptionScript.bangla);
  });

  test('detects mixed script', () {
    expect(
      detector.detect('Napa নাপা 500 মিলিগ্রাম দিনে তিনবার'),
      PrescriptionScript.mixed,
    );
  });

  test('unknown when no letters', () {
    expect(detector.detect('123 ### 456'), PrescriptionScript.unknown);
  });
}
