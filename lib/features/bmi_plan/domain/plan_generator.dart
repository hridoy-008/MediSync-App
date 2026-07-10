import '../../../domain/entities/plan.dart';
import '../../../domain/enums.dart';

/// Rule-based, localized diet + exercise plans mapped to BMI category
/// (PRD P0-8, Open Question Q5 → static tables for v1). All content is
/// clinically conservative and always paired with the medical disclaimer.
class PlanGenerator {
  const PlanGenerator();

  /// [targetKcal] comes from BMI maintenance adjusted by category goal.
  DietPlan diet({
    required BmiCategory category,
    required String localeCode,
    required double maintenanceKcal,
  }) {
    final target = _targetKcal(category, maintenanceKcal);
    final bn = localeCode == 'bn';
    return DietPlan(
      bmiCategory: category,
      localeCode: localeCode,
      targetKcal: target,
      meals: bn ? _dietBn(category) : _dietEn(category),
    );
  }

  ExercisePlan exercise({
    required BmiCategory category,
    required String localeCode,
  }) {
    final bn = localeCode == 'bn';
    return ExercisePlan(
      bmiCategory: category,
      localeCode: localeCode,
      items: bn ? _exerciseBn(category) : _exerciseEn(category),
    );
  }

  int _targetKcal(BmiCategory category, double maintenance) {
    final adjusted = switch (category) {
      BmiCategory.underweight => maintenance + 350,
      BmiCategory.normal => maintenance,
      BmiCategory.overweight => maintenance - 400,
      BmiCategory.obese => maintenance - 600,
    };
    return (adjusted.clamp(1200, 3500) / 10).round() * 10;
  }

  // ---- English diet tables ----
  List<DietMeal> _dietEn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            DietMeal(label: 'Breakfast', items: [
              'Paratha or 2 eggs + milk',
              'Banana + handful of nuts'
            ]),
            DietMeal(label: 'Lunch', items: [
              'Rice + fish/chicken + lentils',
              'Mixed vegetables'
            ]),
            DietMeal(label: 'Snack', items: ['Yogurt + dates', 'Peanut butter toast']),
            DietMeal(label: 'Dinner', items: ['Rice/roti + meat curry', 'Vegetables']),
          ],
        BmiCategory.normal => const [
            DietMeal(label: 'Breakfast', items: ['1 egg + roti + vegetables', 'Fruit']),
            DietMeal(label: 'Lunch', items: ['Rice + fish + lentils', 'Salad']),
            DietMeal(label: 'Snack', items: ['Seasonal fruit', 'Green tea']),
            DietMeal(label: 'Dinner', items: ['Roti + vegetables + chicken', 'Yogurt']),
          ],
        BmiCategory.overweight => const [
            DietMeal(label: 'Breakfast', items: ['Oats + 1 egg white', 'Apple']),
            DietMeal(label: 'Lunch', items: ['Small rice + grilled fish', 'Large salad']),
            DietMeal(label: 'Snack', items: ['Cucumber/carrot', 'Green tea (no sugar)']),
            DietMeal(label: 'Dinner', items: ['2 roti + vegetables + lean protein', 'Soup']),
          ],
        BmiCategory.obese => const [
            DietMeal(label: 'Breakfast', items: ['Vegetable omelette (1 yolk)', 'Citrus fruit']),
            DietMeal(label: 'Lunch', items: ['Brown rice (small) + fish', 'Steamed vegetables']),
            DietMeal(label: 'Snack', items: ['Salad / sprouts', 'Water / green tea']),
            DietMeal(label: 'Dinner', items: ['Grilled chicken + vegetables', 'Clear soup']),
          ],
      };

  // ---- Bangla diet tables ----
  List<DietMeal> _dietBn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            DietMeal(label: 'সকালের নাশতা', items: ['পরোটা বা ২টি ডিম + দুধ', 'কলা + বাদাম']),
            DietMeal(label: 'দুপুরের খাবার', items: ['ভাত + মাছ/মুরগি + ডাল', 'মিশ্র সবজি']),
            DietMeal(label: 'নাশতা', items: ['দই + খেজুর', 'পিনাট বাটার টোস্ট']),
            DietMeal(label: 'রাতের খাবার', items: ['ভাত/রুটি + মাংস', 'সবজি']),
          ],
        BmiCategory.normal => const [
            DietMeal(label: 'সকালের নাশতা', items: ['১টি ডিম + রুটি + সবজি', 'ফল']),
            DietMeal(label: 'দুপুরের খাবার', items: ['ভাত + মাছ + ডাল', 'সালাদ']),
            DietMeal(label: 'নাশতা', items: ['মৌসুমি ফল', 'গ্রিন টি']),
            DietMeal(label: 'রাতের খাবার', items: ['রুটি + সবজি + মুরগি', 'দই']),
          ],
        BmiCategory.overweight => const [
            DietMeal(label: 'সকালের নাশতা', items: ['ওটস + ১টি ডিমের সাদা অংশ', 'আপেল']),
            DietMeal(label: 'দুপুরের খাবার', items: ['অল্প ভাত + গ্রিল মাছ', 'বড় সালাদ']),
            DietMeal(label: 'নাশতা', items: ['শসা/গাজর', 'চিনি ছাড়া গ্রিন টি']),
            DietMeal(label: 'রাতের খাবার', items: ['২টি রুটি + সবজি + চর্বিহীন প্রোটিন', 'স্যুপ']),
          ],
        BmiCategory.obese => const [
            DietMeal(label: 'সকালের নাশতা', items: ['সবজি ওমলেট (১ কুসুম)', 'লেবু জাতীয় ফল']),
            DietMeal(label: 'দুপুরের খাবার', items: ['অল্প ব্রাউন রাইস + মাছ', 'সিদ্ধ সবজি']),
            DietMeal(label: 'নাশতা', items: ['সালাদ / অঙ্কুরিত ছোলা', 'পানি / গ্রিন টি']),
            DietMeal(label: 'রাতের খাবার', items: ['গ্রিল মুরগি + সবজি', 'পরিষ্কার স্যুপ']),
          ],
      };

  // ---- Exercise tables ----
  List<ExerciseItem> _exerciseEn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            ExerciseItem(name: 'Light strength training', durationMins: 30, iconKey: 'strength'),
            ExerciseItem(name: 'Walking', durationMins: 20, iconKey: 'walk'),
            ExerciseItem(name: 'Yoga / stretching', durationMins: 15, iconKey: 'yoga'),
          ],
        BmiCategory.normal => const [
            ExerciseItem(name: 'Brisk walk', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(name: 'Cycling or jogging', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'Stretching', durationMins: 10, iconKey: 'yoga'),
          ],
        BmiCategory.overweight => const [
            ExerciseItem(name: 'Brisk walk', durationMins: 40, iconKey: 'walk'),
            ExerciseItem(name: 'Cardio (cycling/swim)', durationMins: 30, iconKey: 'run'),
            ExerciseItem(name: 'Bodyweight circuit', durationMins: 20, iconKey: 'strength'),
          ],
        BmiCategory.obese => const [
            ExerciseItem(name: 'Walking (start slow)', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(name: 'Low-impact cardio', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'Chair / water exercises', durationMins: 15, iconKey: 'yoga'),
          ],
      };

  List<ExerciseItem> _exerciseBn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            ExerciseItem(name: 'হালকা শক্তি ব্যায়াম', durationMins: 30, iconKey: 'strength'),
            ExerciseItem(name: 'হাঁটা', durationMins: 20, iconKey: 'walk'),
            ExerciseItem(name: 'যোগব্যায়াম / স্ট্রেচিং', durationMins: 15, iconKey: 'yoga'),
          ],
        BmiCategory.normal => const [
            ExerciseItem(name: 'দ্রুত হাঁটা', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(name: 'সাইক্লিং বা জগিং', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'স্ট্রেচিং', durationMins: 10, iconKey: 'yoga'),
          ],
        BmiCategory.overweight => const [
            ExerciseItem(name: 'দ্রুত হাঁটা', durationMins: 40, iconKey: 'walk'),
            ExerciseItem(name: 'কার্ডিও (সাইক্লিং/সাঁতার)', durationMins: 30, iconKey: 'run'),
            ExerciseItem(name: 'বডিওয়েট সার্কিট', durationMins: 20, iconKey: 'strength'),
          ],
        BmiCategory.obese => const [
            ExerciseItem(name: 'হাঁটা (ধীরে শুরু)', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(name: 'কম-প্রভাব কার্ডিও', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'চেয়ার / পানির ব্যায়াম', durationMins: 15, iconKey: 'yoga'),
          ],
      };
}
