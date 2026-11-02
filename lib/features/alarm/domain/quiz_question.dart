/// A multiple-choice question with exactly four options, one of them correct.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  })  : assert(options.length == 4),
        assert(correctIndex >= 0 && correctIndex < 4);

  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];
}
