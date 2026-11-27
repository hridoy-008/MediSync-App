import '../../../domain/enums.dart';

/// Helper to generate activity and status specific friendly motivational messages.
String getMotivationalMessage({
  required String activityTitle,
  required ReminderStatus status,
  required bool isBangla,
}) {
  final titleLower = activityTitle.toLowerCase();

  if (status == ReminderStatus.taken) {
    if (isBangla) {
      return '🎉 দারুণ কাজ! আপনি আপনার স্বাস্থ্যকর অভ্যাসে সঠিক পথে আছেন।';
    }
    return "🎉 Well done! You're staying on track with your healthy routine.";
  }

  if (status == ReminderStatus.snoozed) {
    if (isBangla) {
      return '⏰ রিমাইন্ডার স্নুজ করা হয়েছে। আমরা শীঘ্রই আপনাকে আবার মনে করিয়ে দেব।';
    }
    return "⏰ Reminder snoozed. We'll remind you again soon.";
  }

  if (status == ReminderStatus.missed) {
    if (titleLower.contains('breakfast') || titleLower.contains('নাস্তা')) {
      if (isBangla) {
        return 'আপনি আপনার সকালের নাস্তার রিমাইন্ডার মিস করেছেন। সময়মতো স্বাস্থ্যকর খাবার দিয়ে দিন শুরু করার চেষ্টা করুন।';
      }
      return 'You missed your breakfast reminder. Try to start your day with a healthy meal on time.';
    }
    if (titleLower.contains('water') || titleLower.contains('পানি')) {
      if (isBangla) {
        return 'আপনি আপনার পানির রিমাইন্ডার মিস করেছেন। শরীর সতেজ রাখতে পানি পান করে নিন।';
      }
      return 'You missed your water reminder. Take a moment to hydrate and keep your body refreshed.';
    }
    if (titleLower.contains('lunch') || titleLower.contains('দুপুরের')) {
      if (isBangla) {
        return 'আপনি আপনার দুপুরের খাবারের রিমাইন্ডার মিস করেছেন। শক্তি বজায় রাখতে সময়মতো খাবার খাওয়ার চেষ্টা করুন।';
      }
      return 'You missed your lunch reminder. Try to have your meal on time to keep your energy up.';
    }
    if (titleLower.contains('dinner') || titleLower.contains('রাতের')) {
      if (isBangla) {
        return 'আপনি আপনার রাতের খাবারের রিমাইন্ডার মিস করেছেন। স্বাস্থ্যকর অভ্যাসের জন্য সময়মতো খাবার গ্রহণ করুন।';
      }
      return 'You missed your dinner reminder. Remember to maintain a regular meal schedule for a healthier routine.';
    }
    if (titleLower.contains('wind down') ||
        titleLower.contains('wind-down') ||
        titleLower.contains('রিল্যাক্স')) {
      if (isBangla) {
        return 'আপনি আপনার রিল্যাক্সের রিমাইন্ডার মিস করেছেন। ভালো ঘুমের জন্য নিজেকে প্রস্তুত করার জন্য কিছু সময় দিন।';
      }
      return 'You missed your wind-down reminder. Take some time to relax and prepare your mind for a good night\'s sleep.';
    }
    if (titleLower.contains('bedtime') ||
        titleLower.contains('sleep') ||
        titleLower.contains('ঘুম')) {
      if (isBangla) {
        return 'আপনি আপনার ঘুমের রিমাইন্ডার মিস করেছেন। আজ রাতে সময়মতো ঘুমানোর চেষ্টা করুন এবং শরীরকে প্রয়োজনীয় বিশ্রাম দিন।';
      }
      return 'You missed your bedtime reminder. Try to sleep on time tonight and give your body the rest it needs.';
    }
    if (isBangla) {
      return 'আপনি এই রিমাইন্ডারটি মিস করেছেন। স্বাস্থ্য ঠিক রাখতে সময়মতো আপনার রুটিন মেনে চলার চেষ্টা করুন।';
    }
    return 'You missed this reminder. Try to stay on time to keep your health routine on track.';
  }

  return '';
}
