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
    return "🎉 Well done! You’re staying on track with your healthy routine.";
  }

  if (status == ReminderStatus.snoozed) {
    if (isBangla) {
      return '⏰ রিমাইন্ডার স্নুজ করা হয়েছে। আমরা শীঘ্রই আপনাকে আবার মনে করিয়ে দেব।';
    }
    return "⏰ Reminder snoozed. We’ll remind you again soon.";
  }

  if (status == ReminderStatus.skipped) {
    if (isBangla) {
      return 'এটি ঠিক আছে! আপনি সর্বদা আবার চেষ্টা করতে পারেন। আপনার স্বাস্থ্যকর অভ্যাসগুলির সাথে ধারাবাহিক থাকুন এবং আপনার পরবর্তী রিমাইন্ডারটি গণনা করুন!';
    }
    return "That's okay! You can always try again. Stay consistent with your healthy habits and make your next reminder count!";
  }

  if (status == ReminderStatus.missed) {
    if (isBangla) {
      return 'একটি মিস হওয়া রিমাইন্ডার আপনার অগ্রগতি থামাতে দেবেন না। স্বাস্থ্যকর অভ্যাস গড়ে তুলতে থাকুন!';
    }
    return "Don't let one missed reminder stop your progress. Keep building healthy habits!";
  }

  return '';
}
