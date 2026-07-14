import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/companion/domain/weekly_quest_service.dart';

void main() {
  const service = WeeklyQuestService();

  test('semaine vide : aucune quête complétée', () {
    expect(service.doneCount(const WeeklyProgress()), 0);
  });

  test('quête séances utilise l\'objectif hebdo', () {
    final q = service
        .evaluate(const WeeklyProgress(sessionsThisWeek: 3, sessionsGoal: 3))
        .firstWhere((q) => q.def.id == 'sessions');
    expect(q.target, 3);
    expect(q.done, isTrue);
  });

  test('objectif hebdo nul -> cible par défaut 3', () {
    final q = service
        .evaluate(const WeeklyProgress(sessionsThisWeek: 2, sessionsGoal: 0))
        .firstWhere((q) => q.def.id == 'sessions');
    expect(q.target, 3);
    expect(q.done, isFalse);
  });

  test('quête activité', () {
    expect(
      service
          .evaluate(const WeeklyProgress(activitiesThisWeek: 1))
          .firstWhere((q) => q.def.id == 'activity')
          .done,
      isTrue,
    );
  });

  test('quête minutes actives (150)', () {
    final q = service
        .evaluate(const WeeklyProgress(activeMinutesThisWeek: 75))
        .firstWhere((q) => q.def.id == 'minutes');
    expect(q.done, isFalse);
    expect(q.progress, closeTo(0.5, 0.001));
  });

  test('toutes les quêtes complétées', () {
    const p = WeeklyProgress(
      sessionsThisWeek: 3,
      activitiesThisWeek: 2,
      mobilityOrRestThisWeek: 1,
      distinctKindsThisWeek: 2,
      activeMinutesThisWeek: 200,
      sessionsGoal: 3,
    );
    expect(service.doneCount(p), service.evaluate(p).length);
  });
}
