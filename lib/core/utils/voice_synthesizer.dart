import 'package:flutter_tts/flutter_tts.dart';

class VoiceSynthesizer {
  VoiceSynthesizer._();
  
  static final FlutterTts _tts = FlutterTts();
  
  static Future<void> speakReminder({
    required String title,
    required String subtitle,
    required bool isBangla,
  }) async {
    // Detect if title contains Bangla characters
    final hasBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(title);
    final speakLanguage = (isBangla || hasBangla) ? 'bn-BD' : 'en-US';
    
    try {
      await _tts.setLanguage(speakLanguage);
      await _tts.setPitch(1.0);
      // TTS on some platforms is fast, 0.45-0.5 is ideal for clear hearing of drug names
      await _tts.setSpeechRate(0.5); 
      
      final text = _getSpeechText(
        title: title,
        subtitle: subtitle,
        isBangla: isBangla || hasBangla,
      );
      await _tts.speak(text);
    } catch (e) {
      // Gracefully swallow TTS load errors on simulator/devices without TTS engines
      print('[VoiceSynthesizer] TTS error: $e');
    }
  }
  
  static String _getSpeechText({
    required String title,
    required String subtitle,
    required bool isBangla,
  }) {
    if (isBangla) {
      final String actionTimeText;
      if (subtitle.contains('before food') || subtitle.contains('খাবার পূর্বে') || subtitle.contains('খাবার আগে')) {
        actionTimeText = 'খাবার আগে';
      } else if (subtitle.contains('after food') || subtitle.contains('খাবার পরে')) {
        actionTimeText = 'খাবার পরে';
      } else if (subtitle.contains('with food') || subtitle.contains('খাবারের সাথে')) {
        actionTimeText = 'খাবারের সাথে';
      } else {
        actionTimeText = '';
      }
      
      final doseText = _extractDoseTextBangla(subtitle);
      if (actionTimeText.isNotEmpty) {
        return 'আপনার $actionTimeText $title $doseText নেওয়ার সময় হয়েছে।';
      } else {
        return 'আপনার $title $doseText নেওয়ার সময় হয়েছে।';
      }
    } else {
      final String actionTimeText;
      if (subtitle.contains('before food')) {
        actionTimeText = 'before food';
      } else if (subtitle.contains('after food')) {
        actionTimeText = 'after food';
      } else if (subtitle.contains('with food')) {
        actionTimeText = 'with food';
      } else {
        actionTimeText = '';
      }
      
      final doseText = _extractDoseTextEnglish(subtitle);
      if (actionTimeText.isNotEmpty) {
        return 'It is time to take $doseText of $title $actionTimeText.';
      } else {
        return 'It is time to take $title.';
      }
    }
  }

  static String _extractDoseTextBangla(String subtitle) {
    if (subtitle.isEmpty) return 'ঔষধ';
    final firstPart = subtitle.split('·').first.trim();
    if (firstPart.isEmpty) return 'ঔষধ';
    return firstPart;
  }

  static String _extractDoseTextEnglish(String subtitle) {
    if (subtitle.isEmpty) return 'your dose';
    final firstPart = subtitle.split('·').first.trim();
    if (firstPart.isEmpty) return 'your dose';
    return firstPart;
  }
}
