import '../../../domain/entities/prescription.dart';
import '../../../domain/enums.dart';

class InteractionWarning {
  const InteractionWarning({
    required this.medicines,
    required this.messageEn,
    required this.messageBn,
    this.severity = 'warning', // 'warning' or 'danger'
  });

  final List<String> medicines;
  final String messageEn;
  final String messageBn;
  final String severity;
}

class InteractionChecker {
  InteractionChecker._();

  static final List<Map<String, dynamic>> _drugDrugRules = [
    {
      'keys': ['cipro', 'levo', 'tetra', 'doxy'],
      'conflicts': ['calcium', 'iron', 'antacid', 'magnesium', 'aluminum'],
      'msgEn': 'Taking Fluoroquinolones/Tetracyclines with Calcium, Iron, or Antacids reduces absorption. Space them at least 2 hours apart.',
      'msgBn': 'ক্যালসিয়াম, আয়রন বা অ্যান্টাসিডের সাথে এই অ্যান্টিবায়োটিক খেলে শোষণ কমে যায়। অন্তত ২ ঘণ্টা বিরতি দিয়ে খাবেন।',
      'severity': 'warning',
    },
    {
      'keys': ['iron', 'ferrous'],
      'conflicts': ['calcium', 'antacid'],
      'msgEn': 'Calcium or Antacids inhibit Iron absorption. Take them at different times of the day.',
      'msgBn': 'ক্যালসিয়াম বা অ্যান্টাসিড আয়রন শোষণে বাধা দেয়। এগুলো দিনের আলাদা সময়ে সেবন করুন।',
      'severity': 'warning',
    },
    {
      'keys': ['aspirin', 'ecospirin'],
      'conflicts': ['ibuprofen', 'naproxen', 'diclofenac', 'warfarin', 'clopidogrel'],
      'msgEn': 'Combining Aspirin with other NSAIDs or blood thinners increases the risk of stomach bleeding.',
      'msgBn': 'অ্যাসপিরিনের সাথে অন্য ব্যথানাশক বা রক্ত পাতলা করার ওষুধ খেলে পাকস্থলী থেকে রক্তপাতের ঝুঁকি বাড়ে।',
      'severity': 'danger',
    },
  ];

  static final List<Map<String, dynamic>> _drugFoodRules = [
    {
      'key': 'thyrox',
      'msgEn': 'Thyroxine must be taken on an empty stomach (usually 30-60 mins before breakfast) for proper absorption.',
      'msgBn': 'থাইরক্সিন অবশ্যই খালি পেটে (সাধারণত সকালের নাস্তার ৩০-৬০ মিনিট আগে) খেতে হবে।',
      'severity': 'warning',
    },
    {
      'key': 'iron',
      'msgEn': 'Do not take Iron supplements with Milk, Tea, or Coffee, as they block absorption.',
      'msgBn': 'দুধ, চা বা কফির সাথে আয়রন খাবেন না, কারণ এগুলো আয়রন শোষণে বাধা দেয়।',
      'severity': 'warning',
    },
    {
      'key': 'ferrous',
      'msgEn': 'Do not take Iron supplements with Milk, Tea, or Coffee, as they block absorption.',
      'msgBn': 'দুধ, চা বা কফির সাথে আয়রন খাবেন না, কারণ এগুলো আয়রন শোষণে বাধা দেয়।',
      'severity': 'warning',
    },
    {
      'key': 'metro',
      'msgEn': 'Avoid alcohol while taking Metronidazole to prevent severe nausea, vomiting, and headache.',
      'msgBn': 'মেট্রোনিডাজল খাওয়ার সময় অ্যালকোহল পরিহার করুন, অন্যথায় তীব্র বমিভাব বা মাথাব্যথা হতে পারে।',
      'severity': 'danger',
    },
    {
      'key': 'stat',
      'msgEn': 'Avoid Grapefruit/Grapefruit juice with Statin medications as it increases side effects.',
      'msgBn': 'স্ট্যাটিন জাতীয় ওষুধের সাথে বাতাবি লেবু বা এর জুস খাওয়া পরিহার করুন, এটি পার্শ্বপ্রতিক্রিয়া বাড়াতে পারে।',
      'severity': 'warning',
    },
  ];

  /// Check a list of medicines for potential conflicts.
  static List<InteractionWarning> check(List<Medicine> medicines) {
    final warnings = <InteractionWarning>[];
    final names = medicines.map((m) => m.name.toLowerCase()).toList();

    // 1) Drug-Drug checks
    for (final rule in _drugDrugRules) {
      final keys = rule['keys'] as List<String>;
      final conflicts = rule['conflicts'] as List<String>;

      // Find if we have any medicine matching 'keys'
      final matchingKeyMedIndex = names.indexWhere((name) => keys.any((k) => name.contains(k)));
      if (matchingKeyMedIndex != -1) {
        // Find if we also have any medicine matching 'conflicts'
        final matchingConflictIndex = names.indexWhere((name) => conflicts.any((c) => name.contains(c)));
        if (matchingConflictIndex != -1 && matchingKeyMedIndex != matchingConflictIndex) {
          warnings.add(InteractionWarning(
            medicines: [
              medicines[matchingKeyMedIndex].name,
              medicines[matchingConflictIndex].name,
            ],
            messageEn: rule['msgEn'] as String,
            messageBn: rule['msgBn'] as String,
            severity: rule['severity'] as String,
          ));
        }
      }
    }

    // 2) Drug-Food/Lifestyle checks
    for (final rule in _drugFoodRules) {
      final key = rule['key'] as String;
      final matchingIndex = names.indexWhere((name) => name.contains(key));
      if (matchingIndex != -1) {
        warnings.add(InteractionWarning(
          medicines: [medicines[matchingIndex].name],
          messageEn: rule['msgEn'] as String,
          messageBn: rule['msgBn'] as String,
          severity: rule['severity'] as String,
        ));
      }
    }

    return warnings;
  }
}
