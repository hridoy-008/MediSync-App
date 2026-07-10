/// Shared cross-feature enums. Kept in one place so features never import each
/// other for type definitions (TRD §3).

enum Sex { male, female, other }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum BmiCategory { underweight, normal, overweight, obese }

/// When a medicine should be taken relative to food.
enum FoodTiming { beforeFood, afterFood, withFood, anyTime }

enum ReminderType { medicine, meal, water, sleep }

enum MealType { breakfast, midMorning, lunch, afternoon, dinner, bedtimeSnack }

/// Lifecycle of a single reminder occurrence.
enum ReminderStatus { pending, taken, snoozed, skipped, missed }

/// User action taken on a reminder notification.
enum ReminderAction { taken, snoozed, skipped, missed }

/// Confidence of an extracted field (drives the review UI flags — PRD P0-2).
enum FieldConfidence { high, medium, low }

enum PrescriptionSource { camera, gallery }

enum OcrEngine { onDeviceMlKit, cloudVision }

/// Detected script of a prescription, used for OCR routing (TRD §5).
enum PrescriptionScript { latin, bangla, mixed, unknown }
