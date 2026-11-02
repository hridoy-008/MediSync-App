import 'quiz_question.dart';

enum QuizAnswerResult { correct, wrong, completed }

/// Progress through one alarm's quiz. Questions cannot be skipped: the index
/// only advances on a correct answer and the quiz is complete only after every
/// question has been answered correctly.
class QuizSession {
  QuizSession(List<QuizQuestion> questions)
      : assert(questions.isNotEmpty),
        questions = List.unmodifiable(questions);

  final List<QuizQuestion> questions;
  int _index = 0;
  int _wrongAttempts = 0;

  int get total => questions.length;
  int get currentIndex => _index;
  int get wrongAttempts => _wrongAttempts;
  bool get isCompleted => _index >= questions.length;
  QuizQuestion get current => questions[_index.clamp(0, questions.length - 1)];

  QuizAnswerResult submit(int optionIndex) {
    if (isCompleted) return QuizAnswerResult.completed;
    if (optionIndex == current.correctIndex) {
      _index++;
      return isCompleted ? QuizAnswerResult.completed : QuizAnswerResult.correct;
    }
    _wrongAttempts++;
    return QuizAnswerResult.wrong;
  }
}
