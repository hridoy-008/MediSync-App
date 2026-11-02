import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/features/alarm/application/alarm_session_service.dart';
import 'package:medisync/features/alarm/application/quiz_service.dart';
import 'package:medisync/features/alarm/data/quiz_question_bank.dart';
import 'package:medisync/features/alarm/domain/quiz_session.dart';

void main() {
  group('question bank', () {
    test('ids unique, four distinct options each', () {
      expect(quizQuestionBank.map((q) => q.id).toSet().length,
          quizQuestionBank.length);
      for (final q in quizQuestionBank) {
        final opts = [q.correct, ...q.wrong];
        expect(opts.length, 4, reason: q.id);
        expect(opts.toSet().length, 4, reason: q.id);
      }
      expect(quizQuestionBank.length, greaterThanOrEqualTo(30));
    });
  });

  group('QuizService', () {
    test('creates 3-5 questions with one correct option', () async {
      final svc = QuizService(random: Random(1));
      for (final count in [1, 3, 4, 5, 9]) {
        final s = await svc.createSession(count: count);
        expect(s.total, inInclusiveRange(3, 5));
        for (final q in s.questions) {
          expect(q.options.length, 4);
          final raw = quizQuestionBank.firstWhere((r) => r.id == q.id);
          expect(q.correctAnswer, raw.correct);
        }
      }
    });

    test('avoids repeating recent questions across sessions', () async {
      final svc = QuizService(random: Random(7));
      final a = await svc.createSession(count: 5);
      final b = await svc.createSession(count: 5);
      final idsA = a.questions.map((q) => q.id).toSet();
      expect(b.questions.any((q) => idsA.contains(q.id)), isFalse);
    });
  });

  group('QuizSession', () {
    Future<QuizSession> make() =>
        QuizService(random: Random(3)).createSession(count: 3);

    test('wrong answer does not advance or complete', () async {
      final s = await make();
      final wrong = (s.current.correctIndex + 1) % 4;
      expect(s.submit(wrong), QuizAnswerResult.wrong);
      expect(s.currentIndex, 0);
      expect(s.isCompleted, isFalse);
      expect(s.wrongAttempts, 1);
    });

    test('completes only after every question is answered correctly',
        () async {
      final s = await make();
      expect(s.submit(s.current.correctIndex), QuizAnswerResult.correct);
      expect(s.submit(s.current.correctIndex), QuizAnswerResult.correct);
      expect(s.isCompleted, isFalse);
      expect(s.submit(s.current.correctIndex), QuizAnswerResult.completed);
      expect(s.isCompleted, isTrue);
    });
  });

  group('AlarmSessionService', () {
    test('prevents duplicate sessions and stops exactly once', () async {
      final svc = AlarmSessionService.forTest(QuizService(random: Random(2)));
      final t = DateTime(2026, 1, 1, 7);
      expect(await svc.begin(t), isTrue);
      expect(await svc.begin(t), isFalse); // duplicate while active
      expect(svc.isActive, isTrue);
      expect(svc.tryFinish(), isTrue);
      expect(svc.tryFinish(), isFalse); // second stop is a no-op
      expect(await svc.begin(t), isFalse); // already completed
      expect(await svc.begin(t.add(const Duration(days: 1))), isTrue);
    });
  });
}
