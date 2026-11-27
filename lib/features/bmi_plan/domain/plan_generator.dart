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

  // ---- English diet tables with 3 options per meal ----
  List<DietMeal> _dietEn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            DietMeal(label: 'Breakfast', options: [
              DietMealOption(title: 'Option 1: Classic', items: ['Paratha or 2 eggs + milk', 'Banana + handful of nuts']),
              DietMealOption(title: 'Option 2: Smoothie Bowl', items: ['Oats banana peanut butter smoothie', 'Boiled eggs']),
              DietMealOption(title: 'Option 3: Heavy Roti', items: ['Roti with mashed potato & beef curry', 'Glass of milk']),
            ]),
            DietMeal(label: 'Lunch', options: [
              DietMealOption(title: 'Option 1: Traditional Rice', items: ['Rice + fish/chicken curry + lentils', 'Mixed vegetables']),
              DietMealOption(title: 'Option 2: Special Feast', items: ['Chicken polao + roast chicken', 'Green vegetable salad']),
              DietMealOption(title: 'Option 3: Kichuri Meal', items: ['Beef/chicken kichuri + egg curry', 'Pickles & yogurt']),
            ]),
            DietMeal(label: 'Snack', options: [
              DietMealOption(title: 'Option 1: Sweet Snack', items: ['Yogurt + dates & honey', 'Handful of almonds']),
              DietMealOption(title: 'Option 2: Toast Snack', items: ['Peanut butter toast with banana slices', 'Boiled egg']),
              DietMealOption(title: 'Option 3: Energy Bite', items: ['Dry fruits & nuts mix', 'Glass of fresh juice']),
            ]),
            DietMeal(label: 'Dinner', options: [
              DietMealOption(title: 'Option 1: Standard Dinner', items: ['Rice/roti + meat curry', 'Sautéed vegetables']),
              DietMealOption(title: 'Option 2: Western Style', items: ['Pasta with chicken & cheese', 'Vegetable soup']),
              DietMealOption(title: 'Option 3: Heavy Roti & Kebab', items: ['Naan/roti + mutton/beef kebab', 'Fresh salad']),
            ]),
          ],
        BmiCategory.normal => const [
            DietMeal(label: 'Breakfast', options: [
              DietMealOption(title: 'Option 1: Healthy Start', items: ['1 egg + roti + mixed vegetables', 'Fresh fruit']),
              DietMealOption(title: 'Option 2: Oatmeal', items: ['Oatmeal with milk & fresh fruits', 'Boiled egg']),
              DietMealOption(title: 'Option 3: Toast & Tea', items: ['Bread toast with butter', '1 boiled egg & green tea']),
            ]),
            DietMeal(label: 'Lunch', options: [
              DietMealOption(title: 'Option 1: Balanced Rice', items: ['Rice + fish curry + lentils', 'Fresh salad']),
              DietMealOption(title: 'Option 2: Lean Protein', items: ['Brown rice + chicken breast', 'Vegetable soup']),
              DietMealOption(title: 'Option 3: Roti & Fish', items: ['Roti + vegetable curry + dal', 'Fish fry']),
            ]),
            DietMeal(label: 'Snack', options: [
              DietMealOption(title: 'Option 1: Fresh Fruit', items: ['Seasonal fresh fruit']),
              DietMealOption(title: 'Option 2: Tea & Nuts', items: ['Green tea', 'Handful of mixed nuts']),
              DietMealOption(title: 'Option 3: Dairy Snack', items: ['Low-fat yogurt or buttermilk']),
            ]),
            DietMeal(label: 'Dinner', options: [
              DietMealOption(title: 'Option 1: Roti & Chicken', items: ['Roti + vegetable curry + chicken', 'Yogurt']),
              DietMealOption(title: 'Option 2: Light Fish Soup', items: ['Light rice + fish soup', 'Vegetable mix']),
              DietMealOption(title: 'Option 3: Soup & Salad', items: ['Vegetable soup + boiled vegetables', 'Grilled fish']),
            ]),
          ],
        BmiCategory.overweight => const [
            DietMeal(label: 'Breakfast', options: [
              DietMealOption(title: 'Option 1: Light Oats', items: ['Oats porridge + 1 egg white', 'Apple']),
              DietMealOption(title: 'Option 2: Whole Wheat', items: ['Whole wheat toast + green tea', 'Boiled egg white']),
              DietMealOption(title: 'Option 3: Chia Seed', items: ['Chia seed pudding with fruit', 'Black coffee/tea']),
            ]),
            DietMeal(label: 'Lunch', options: [
              DietMealOption(title: 'Option 1: Grilled Fish', items: ['Small portion brown rice + grilled fish', 'Large green salad']),
              DietMealOption(title: 'Option 2: Lean Chicken', items: ['Roti (2 pcs) + chicken breast', 'Cucumber tomato salad']),
              DietMealOption(title: 'Option 3: Soup & Dal', items: ['Vegetable soup + boiled chicken', 'Thin lentil soup']),
            ]),
            DietMeal(label: 'Snack', options: [
              DietMealOption(title: 'Option 1: Veggie Sticks', items: ['Cucumber & carrot sticks with lemon']),
              DietMealOption(title: 'Option 2: Roasted Chhola', items: ['Green tea (no sugar)', 'Handful of roasted chickpeas']),
              DietMealOption(title: 'Option 3: Lemon Water', items: ['Low-fat yogurt or lemon water']),
            ]),
            DietMeal(label: 'Dinner', options: [
              DietMealOption(title: 'Option 1: Roti & Veggies', items: ['2 roti + mixed vegetables + lean protein']),
              DietMealOption(title: 'Option 2: Clear Soup', items: ['Clear chicken/vegetable soup', 'Grilled fish']),
              DietMealOption(title: 'Option 3: Sweet Potato', items: ['Boiled sweet potato + salad', 'Egg white omelette']),
            ]),
          ],
        BmiCategory.obese => const [
            DietMeal(label: 'Breakfast', options: [
              DietMealOption(title: 'Option 1: Veg Omelette', items: ['Vegetable omelette (1 yolk only)', 'Citrus fruit']),
              DietMealOption(title: 'Option 2: Sprout Bowl', items: ['Warm lemon water + sprouted mung beans']),
              DietMealOption(title: 'Option 3: Cinnamon Oats', items: ['Oats with water/skim milk + cinnamon']),
            ]),
            DietMeal(label: 'Lunch', options: [
              DietMealOption(title: 'Option 1: Steamed Fish', items: ['Small brown rice + steamed fish', 'Large boiled vegetable bowl']),
              DietMealOption(title: 'Option 2: Quinoa Salad', items: ['Quinoa or brown rice salad with boiled chicken breast']),
              DietMealOption(title: 'Option 3: Veg Soup & Chicken', items: ['Clear vegetable soup + grilled chicken', 'Raw salad']),
            ]),
            DietMeal(label: 'Snack', options: [
              DietMealOption(title: 'Option 1: Raw Sprouts', items: ['Raw salad or sprouts (chhola)']),
              DietMealOption(title: 'Option 2: Ginger Tea', items: ['Green tea with ginger + cucumber slices']),
              DietMealOption(title: 'Option 3: Chia Water', items: ['Warm water with chia seeds']),
            ]),
            DietMeal(label: 'Dinner', options: [
              DietMealOption(title: 'Option 1: Lean Grilled', items: ['Grilled chicken breast + steamed vegetables']),
              DietMealOption(title: 'Option 2: Tofu Soup', items: ['Clear vegetable soup with tofu/chicken']),
              DietMealOption(title: 'Option 3: Baked Fish', items: ['Baked/boiled fish with lemon & pepper', 'Lettuce salad']),
            ]),
          ],
      };

  // ---- Bangla diet tables with 3 options per meal ----
  List<DietMeal> _dietBn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            DietMeal(label: 'সকালের নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: ক্লাসিক', items: ['পরোটা বা ২টি ডিম + দুধ', 'কলা + বাদাম']),
              DietMealOption(title: 'বিকল্প ২: স্মুদি বোল', items: ['ওটস কলা ও পিনাট বাটার স্মুদি', 'সিদ্ধ ডিম']),
              DietMealOption(title: 'বিকল্প ৩: ভারী রুটি', items: ['আলু ভর্তা ও গরুর মাংসের ঝোলসহ রুটি', 'এক গ্লাস দুধ']),
            ]),
            DietMeal(label: 'দুপুরের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: ঐতিহ্যবাহী ভাত', items: ['ভাত + মাছ/মুরগির মাংস + ডাল', 'মিশ্র সবজি']),
              DietMealOption(title: 'বিকল্প ২: স্পেশাল পোলাও', items: ['চিকেন পোলাও + রোস্ট', 'সবজি সালাদ']),
              DietMealOption(title: 'বিকল্প ৩: খিচুড়ি', items: ['গরুর বা মুরগির মাংসের খিচুড়ি', 'আচার ও টক দই']),
            ]),
            DietMeal(label: 'নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: মিষ্টি নাশতা', items: ['দই + খেজুর ও মধু', 'কিছু বাদাম']),
              DietMealOption(title: 'বিকল্প ২: টোস্ট', items: ['পিনাট বাটার টোস্ট ও কলার স্লাইস', 'সিদ্ধ ডিম']),
              DietMealOption(title: 'বিকল্প ৩: ড্রাই ফ্রুটস', items: ['ড্রাই ফ্রুটস ও কাজুবাদাম মিশ্রণ', 'তাজা জুস']),
            ]),
            DietMeal(label: 'রাতের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: সাধারণ ডিনার', items: ['ভাত/রুটি + মাংসের তরকারি', 'ভাজা সবজি']),
              DietMealOption(title: 'বিকল্প ২: পাস্তা', items: ['চিকেন ও চিজ দিয়ে পাস্তা', 'সবজির স্যুপ']),
              DietMealOption(title: 'বিকল্প ৩: নান ও কাবাব', items: ['নান বা রুটি + মাটন/বিফ কাবাব', 'তাজা সালাদ']),
            ]),
          ],
        BmiCategory.normal => const [
            DietMeal(label: 'সকালের নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: সুষম নাশতা', items: ['১টি ডিম + রুটি + সবজি', 'মৌসুমি ফল']),
              DietMealOption(title: 'বিকল্প ২: ওটমিল', items: ['দুধ ও ফল দিয়ে ওটমিল', 'সিদ্ধ ডিম']),
              DietMealOption(title: 'বিকল্প ৩: টোস্ট ও চা', items: ['মাখন দেওয়া রুটি টোস্ট', '১টি সিদ্ধ ডিম ও গ্রিন টি']),
            ]),
            DietMeal(label: 'দুপুরের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: ভাতের সাথে মাছ', items: ['ভাত + মাছের ঝোল + ডাল', 'সালাদ']),
              DietMealOption(title: 'বিকল্প ২: ব্রাউন রাইস ও চিকেন', items: ['ব্রাউন রাইস + মুরগির মাংস', 'সবজির স্যুপ']),
              DietMealOption(title: 'বিকল্প ৩: রুটি ও মাছ', items: ['রুটি + সবজি + ডাল', 'মাছ ভাজা']),
            ]),
            DietMeal(label: 'নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: ফল', items: ['মৌসুমি তাজা ফল']),
              DietMealOption(title: 'বিকল্প ২: চা ও বাদাম', items: ['গ্রিন টি', 'কিছু মিশ্র বাদাম']),
              DietMealOption(title: 'বিকল্প ৩: দই', items: ['টক দই বা মাঠা']),
            ]),
            DietMeal(label: 'রাতের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: রুটি ও মুরগি', items: ['রুটি + সবজি + মুরগির মাংস', 'দই']),
              DietMealOption(title: 'বিকল্প ২: হালকা মাছের স্যুপ', items: ['হালকা ভাত + মাছের পাতলা ঝোল', 'সবজি']),
              DietMealOption(title: 'বিকল্প ৩: স্যুপ ও সালাদ', items: ['সবজির স্যুপ + সিদ্ধ সবজি', 'গ্রিল মাছ']),
            ]),
          ],
        BmiCategory.overweight => const [
            DietMeal(label: 'সকালের নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: হালকা ওটস', items: ['ওটস পরিজ + ১টি ডিমের সাদা অংশ', 'আপেল']),
              DietMealOption(title: 'বিকল্প ২: আটার রুটি', items: ['লাল আটার রুটি + গ্রিন টি', 'ডিমের সাদা অংশ']),
              DietMealOption(title: 'বিকল্প ৩: চিয়াসিড পুডিং', items: ['ফল দিয়ে চিয়াসিড পুডিং', 'ব্ল্যাক কফি/চা']),
            ]),
            DietMeal(label: 'দুপুরের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: গ্রিল মাছ', items: ['অল্প ব্রাউন রাইস + গ্রিল মাছ', 'বড় সালাদ']),
              DietMealOption(title: 'বিকল্প ২: মুরগির সিনা', items: ['২টি রুটি + মুরগির মাংসের সিনা', 'শসা-টমেটো সালাদ']),
              DietMealOption(title: 'বিকল্প ৩: স্যুপ ও ডাল', items: ['সবজির স্যুপ + সিদ্ধ মুরগি', 'পাতলা ডাল']),
            ]),
            DietMeal(label: 'নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: শসা ও গাজর', items: ['লেবুসহ শসা ও গাজরের স্লাইস']),
              DietMealOption(title: 'বিকল্প ২: ভাজা ছোলা', items: ['চিনি ছাড়া গ্রিন টি', 'একমুঠো ভাজা ছোলা']),
              DietMealOption(title: 'বিকল্প ৩: লেবু পানি', items: ['লো-ফ্যাট দই বা লেবুর পানি']),
            ]),
            DietMeal(label: 'রাতের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: রুটি ও সবজি', items: ['২টি রুটি + মিশ্র সবজি + লিন প্রোটিন']),
              DietMealOption(title: 'বিকল্প ২: ক্লিয়ার স্যুপ', items: ['ক্লিয়ার চিকেন/ভেজিটেবল স্যুপ', 'গ্রিল মাছ']),
              DietMealOption(title: 'বিকল্প ৩: মিষ্টি আলু', items: ['সিদ্ধ মিষ্টি আলু + সালাদ', 'ডিমের সাদা অংশের ওমলেট']),
            ]),
          ],
        BmiCategory.obese => const [
            DietMeal(label: 'সকালের নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: সবজি ওমলেট', items: ['সবজি ওমলেট (১টি কুসুমসহ)', 'লেবু জাতীয় ফল']),
              DietMealOption(title: 'বিকল্প ২: মুগ ডাল ও লেবু পানি', items: ['কুসুম গরম লেবু পানি + ভেজানো মুগ ডাল']),
              DietMealOption(title: 'বিকল্প ৩: দারুচিনি ওটস', items: ['পানি/লো-ফ্যাট দুধ দিয়ে ওটস + দারুচিনি গুঁড়ো']),
            ]),
            DietMeal(label: 'দুপুরের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: সিদ্ধ মাছ ও সবজি', items: ['অল্প ব্রাউন রাইস + সিদ্ধ মাছ', 'বড় বাটি সিদ্ধ সবজি']),
              DietMealOption(title: 'বিকল্প ২: কিনোয়া সালাদ', items: ['সিদ্ধ মুরগির মাংসসহ কিনোয়া বা ব্রাউন রাইস সালাদ']),
              DietMealOption(title: 'বিকল্প ৩: ভেজ স্যুপ ও গ্রিল চিকেন', items: ['ক্লিয়ার ভেজেটেবল স্যুপ + গ্রিল চিকেন', 'কাঁচা সালাদ']),
            ]),
            DietMeal(label: 'নাশতা', options: [
              DietMealOption(title: 'বিকল্প ১: অঙ্কুরিত ছোলা', items: ['কাঁচা সালাদ বা অঙ্কুরিত ছোলা']),
              DietMealOption(title: 'বিকল্প ২: আদা চা', items: ['আদা দিয়ে গ্রিন টি + শসার টুকরো']),
              DietMealOption(title: 'বিকল্প ৩: চিয়া ওয়াটার', items: ['চিয়া সিড ভেজানো কুসুম গরম পানি']),
            ]),
            DietMeal(label: 'রাতের খাবার', options: [
              DietMealOption(title: 'বিকল্প ১: গ্রিল চিকেন', items: ['গ্রিল চিকেন ব্রেস্ট + ভাপানো সবজি']),
              DietMealOption(title: 'বিকল্প ২: টোফু স্যুপ', items: ['টোফু বা চিকেন দিয়ে ক্লিয়ার স্যুপ']),
              DietMealOption(title: 'বিকল্প ৩: বেকড মাছ', items: ['লেবু ও গোলমরিচ দিয়ে বেকড/সিদ্ধ মাছ', 'লেটুস সালাদ']),
            ]),
          ],
      };

  // ---- Exercise tables ----
  List<ExerciseItem> _exerciseEn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            ExerciseItem(
                name: 'Light strength training',
                durationMins: 30,
                iconKey: 'strength'),
            ExerciseItem(name: 'Walking', durationMins: 20, iconKey: 'walk'),
            ExerciseItem(
                name: 'Yoga / stretching', durationMins: 15, iconKey: 'yoga'),
          ],
        BmiCategory.normal => const [
            ExerciseItem(name: 'Brisk walk', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(
                name: 'Cycling or jogging', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'Stretching', durationMins: 10, iconKey: 'yoga'),
          ],
        BmiCategory.overweight => const [
            ExerciseItem(name: 'Brisk walk', durationMins: 40, iconKey: 'walk'),
            ExerciseItem(
                name: 'Cardio (cycling/swim)',
                durationMins: 30,
                iconKey: 'run'),
            ExerciseItem(
                name: 'Bodyweight circuit',
                durationMins: 20,
                iconKey: 'strength'),
          ],
        BmiCategory.obese => const [
            ExerciseItem(
                name: 'Walking (start slow)',
                durationMins: 30,
                iconKey: 'walk'),
            ExerciseItem(
                name: 'Low-impact cardio', durationMins: 20, iconKey: 'run'),
            ExerciseItem(
                name: 'Chair / water exercises',
                durationMins: 15,
                iconKey: 'yoga'),
          ],
      };

  List<ExerciseItem> _exerciseBn(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const [
            ExerciseItem(
                name: 'হালকা শক্তি ব্যায়াম',
                durationMins: 30,
                iconKey: 'strength'),
            ExerciseItem(name: 'হাঁটা', durationMins: 20, iconKey: 'walk'),
            ExerciseItem(
                name: 'যোগব্যায়াম / স্ট্রেচিং',
                durationMins: 15,
                iconKey: 'yoga'),
          ],
        BmiCategory.normal => const [
            ExerciseItem(
                name: 'দ্রুত হাঁটা', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(
                name: 'সাইক্লিং বা জগিং', durationMins: 20, iconKey: 'run'),
            ExerciseItem(name: 'স্ট্রেচিং', durationMins: 10, iconKey: 'yoga'),
          ],
        BmiCategory.overweight => const [
            ExerciseItem(
                name: 'দ্রুত হাঁটা', durationMins: 40, iconKey: 'walk'),
            ExerciseItem(
                name: 'কার্ডিও (সাইক্লিং/সাঁতার)',
                durationMins: 30,
                iconKey: 'run'),
            ExerciseItem(
                name: 'বডিওয়েট সার্কিট',
                durationMins: 20,
                iconKey: 'strength'),
          ],
        BmiCategory.obese => const [
            ExerciseItem(
                name: 'হাঁটা (ধীরে শুরু)', durationMins: 30, iconKey: 'walk'),
            ExerciseItem(
                name: 'কম-প্রভাব কার্ডিও', durationMins: 20, iconKey: 'run'),
            ExerciseItem(
                name: 'চেয়ার / পানির ব্যায়াম',
                durationMins: 15,
                iconKey: 'yoga'),
          ],
      };
}
