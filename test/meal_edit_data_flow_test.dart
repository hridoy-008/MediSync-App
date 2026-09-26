import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/domain/entities/configs.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/reminder_generator.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';

void main() {
  group('Meal Edit Data Flow Unit Tests', () {
    test(
        'MealConfig serialization & deserialization with photo, description, and recommended food',
        () {
      const original = MealConfig(
        id: 'meal_lunch',
        mealType: MealType.lunch,
        minutesFromMidnight: 13 * 60,
        enabled: true,
        description: 'Take lunch after afternoon medicine.',
        imagePath: '/data/user/0/com.medisync/app_flutter/meal_lunch_123.jpg',
        recommendedFood: 'Rice • Fish • Vegetables',
      );

      final map = original.toMap();
      expect(map['id'], 'meal_lunch');
      expect(map['mealType'], 'lunch');
      expect(map['minutesFromMidnight'], 780);
      expect(map['description'], 'Take lunch after afternoon medicine.');
      expect(
        map['imagePath'],
        '/data/user/0/com.medisync/app_flutter/meal_lunch_123.jpg',
      );
      expect(map['recommendedFood'], 'Rice • Fish • Vegetables');

      final restored = MealConfig.fromMap(map);
      expect(restored, equals(original));
      expect(restored.description, 'Take lunch after afternoon medicine.');
      expect(
        restored.imagePath,
        '/data/user/0/com.medisync/app_flutter/meal_lunch_123.jpg',
      );
      expect(restored.recommendedFood, 'Rice • Fish • Vegetables');
    });

    test('MealConfig copyWith allows setting and clearing fields', () {
      const meal = MealConfig(
        id: 'meal_lunch',
        mealType: MealType.lunch,
        minutesFromMidnight: 14 * 60,
        description: 'Initial description',
        imagePath: '/path/to/img.jpg',
        recommendedFood: 'Salad',
      );

      final updated = meal.copyWith(
        description: 'Updated lunch notes',
        imagePath: '/path/to/new_img.jpg',
        recommendedFood: 'Rice and chicken',
      );
      expect(updated.description, 'Updated lunch notes');
      expect(updated.imagePath, '/path/to/new_img.jpg');
      expect(updated.recommendedFood, 'Rice and chicken');

      final cleared = updated.copyWith(
        clearDescription: true,
        clearImagePath: true,
        clearRecommendedFood: true,
      );
      expect(cleared.description, isNull);
      expect(cleared.imagePath, isNull);
      expect(cleared.recommendedFood, isNull);
    });

    test(
        'TimelineBuilder binds MealConfig with photo and description to TimelineItem',
        () {
      const generator = ReminderGenerator();
      const builder = TimelineBuilder();

      final meals = [
        const MealConfig(
          id: 'meal_breakfast',
          mealType: MealType.breakfast,
          minutesFromMidnight: 8 * 60,
          description: 'Eat light breakfast',
          recommendedFood: 'Oats + egg',
        ),
        const MealConfig(
          id: 'meal_lunch',
          mealType: MealType.lunch,
          minutesFromMidnight: 13 * 60,
          description: 'Take lunch after medicine.',
          imagePath: '/data/user/0/com.medisync/app_flutter/meal_lunch.jpg',
          recommendedFood: 'Rice • Fish • Vegetables',
        ),
        const MealConfig(
          id: 'meal_dinner',
          mealType: MealType.dinner,
          minutesFromMidnight: 20 * 60,
          description: 'Light dinner before 9 PM',
          recommendedFood: 'Roti + soup',
        ),
      ];

      final reminders = generator.fromMeals(meals);
      final today = DateTime(2026, 9, 13);
      final items = builder.buildForDay(
        reminders: reminders,
        logs: const [],
        day: today,
        meals: meals,
      );

      final lunchItem = items.firstWhere(
        (i) =>
            i.reminder.mealType == MealType.lunch &&
            !i.reminder.id.contains('_pre_'),
      );

      expect(lunchItem.mealConfig, isNotNull);
      expect(lunchItem.mealConfig!.id, 'meal_lunch');
      expect(lunchItem.mealDescription, 'Take lunch after medicine.');
      expect(
        lunchItem.mealImagePath,
        '/data/user/0/com.medisync/app_flutter/meal_lunch.jpg',
      );
      expect(lunchItem.recommendedFood, 'Rice • Fish • Vegetables');

      final breakfastItem = items.firstWhere(
        (i) =>
            i.reminder.mealType == MealType.breakfast &&
            !i.reminder.id.contains('_pre_'),
      );
      expect(breakfastItem.mealDescription, 'Eat light breakfast');
      expect(breakfastItem.mealImagePath, isNull);
      expect(breakfastItem.recommendedFood, 'Oats + egg');
    });

    test('Updating Lunch does not mutate Breakfast or Dinner configs', () {
      final initialMeals = MealConfig.defaults();
      expect(initialMeals.length, 3);

      const updatedLunch = MealConfig(
        id: 'meal_lunch',
        mealType: MealType.lunch,
        minutesFromMidnight: 13 * 60,
        description: 'New Lunch Note',
        imagePath: '/path/lunch.jpg',
        recommendedFood: 'Rice • Fish',
      );

      final updatedList = initialMeals
          .map((m) => m.id == updatedLunch.id ? updatedLunch : m)
          .toList();

      final breakfast =
          updatedList.firstWhere((m) => m.id == 'meal_breakfast');
      final lunch = updatedList.firstWhere((m) => m.id == 'meal_lunch');
      final dinner = updatedList.firstWhere((m) => m.id == 'meal_dinner');

      expect(lunch.description, 'New Lunch Note');
      expect(lunch.imagePath, '/path/lunch.jpg');
      expect(lunch.recommendedFood, 'Rice • Fish');
      expect(breakfast.description, isNull);
      expect(breakfast.imagePath, isNull);
      expect(dinner.description, isNull);
      expect(dinner.imagePath, isNull);
    });
  });
}
