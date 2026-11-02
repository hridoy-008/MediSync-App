import 'dart:math';

import '../../../core/data/local_store.dart';
import '../data/quiz_question_bank.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_session.dart';

/// Persists the ids of recently asked questions so consecutive alarms differ.
abstract class QuizHistoryStore {
  List<String> read();
  Future<void> write(List<String> ids);
}

class InMemoryQuizHistoryStore implements QuizHistoryStore {
  List<String> _ids = [];

  @override
  List<String> read() => List.of(_ids);

  @override
  Future<void> write(List<String> ids) async => _ids = List.of(ids);
}

class HiveQuizHistoryStore implements QuizHistoryStore {
  static const _key = 'quiz_history';

  @override
  List<String> read() {
    try {
      final raw = LocalStore.instance.singletons.get(_key);
      if (raw == null) return [];
      return (LocalStore.normalize(raw)['ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> write(List<String> ids) async {
    try {
      await LocalStore.instance.singletons.put(_key, {'ids': ids});
    } catch (_) {}
  }
}

/// Builds offline quiz sessions from the local question bank.
class QuizService {
  QuizService({
    List<RawQuizQuestion>? bank,
    Random? random,
    QuizHistoryStore? history,
    this.historySize = 24,
  })  : _bank = bank ?? quizQuestionBank,
        _random = random ?? Random(),
        _history = history ?? InMemoryQuizHistoryStore();

  static const int minQuestions = 3;
  static const int maxQuestions = 5;

  final List<RawQuizQuestion> _bank;
  final Random _random;
  final QuizHistoryStore _history;
  final int historySize;

  /// Picks [count] (clamped to 3–5) questions, preferring ones not asked in
  /// recent sessions, with the options of each shuffled.
  Future<QuizSession> createSession({int count = 4}) async {
    final n = count.clamp(minQuestions, maxQuestions).clamp(1, _bank.length);
    final recent = _history.read();

    final fresh = _bank.where((q) => !recent.contains(q.id)).toList()
      ..shuffle(_random);
    final picked = fresh.take(n).toList();

    if (picked.length < n) {
      // Not enough unseen questions: reuse the least recently asked first.
      final stale = recent
          .where((id) => !picked.any((q) => q.id == id))
          .map((id) => _bank.where((q) => q.id == id))
          .expand((e) => e)
          .take(n - picked.length);
      picked.addAll(stale);
    }

    final updated = [...recent, ...picked.map((q) => q.id)];
    await _history.write(updated.length > historySize
        ? updated.sublist(updated.length - historySize)
        : updated);

    return QuizSession(picked.map(_shuffled).toList());
  }

  QuizQuestion _shuffled(RawQuizQuestion raw) {
    final q = raw.toQuestion();
    final options = List.of(q.options)..shuffle(_random);
    return QuizQuestion(
      id: q.id,
      text: q.text,
      options: options,
      correctIndex: options.indexOf(q.correctAnswer),
    );
  }
}
