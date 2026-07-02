import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/features/streaks/domain/streak_service.dart';

void main() {
  const service = StreakService();

  group('classifyDay', () {
    test('séance prévue et complétée => programme + activité', () {
      final events = service.classifyDay(const DayContext(
        sessionWasPlanned: true,
        restWasPlanned: false,
        sessionCompleted: true,
        sessionPartial: false,
        hadFreeActivity: false,
      ));
      expect(events, contains(StreakEventType.programRespected));
      expect(events, contains(StreakEventType.activity));
    });

    test('séance prévue partielle => activité sans programme respecté', () {
      final events = service.classifyDay(const DayContext(
        sessionWasPlanned: true,
        restWasPlanned: false,
        sessionCompleted: false,
        sessionPartial: true,
        hadFreeActivity: false,
      ));
      expect(events, contains(StreakEventType.activity));
      expect(events, isNot(contains(StreakEventType.programRespected)));
      expect(events, isNot(contains(StreakEventType.programMissed)));
    });

    test('séance prévue non réalisée => programme manqué', () {
      final events = service.classifyDay(const DayContext(
        sessionWasPlanned: true,
        restWasPlanned: false,
        sessionCompleted: false,
        sessionPartial: false,
        hadFreeActivity: false,
      ));
      expect(events, contains(StreakEventType.programMissed));
    });

    test('repos prévu => restDay, ne casse pas le programme (R-004)', () {
      final events = service.classifyDay(const DayContext(
        sessionWasPlanned: false,
        restWasPlanned: true,
        sessionCompleted: false,
        sessionPartial: false,
        hadFreeActivity: false,
      ));
      expect(events, contains(StreakEventType.restDay));
      expect(events, isNot(contains(StreakEventType.programMissed)));
    });

    test('activité hors programme => bonus + activité (R-005)', () {
      final events = service.classifyDay(const DayContext(
        sessionWasPlanned: false,
        restWasPlanned: false,
        sessionCompleted: false,
        sessionPartial: false,
        hadFreeActivity: true,
      ));
      expect(events, contains(StreakEventType.bonus));
      expect(events, contains(StreakEventType.activity));
    });
  });

  group('programStreak', () {
    test('un repos prévu au milieu ne casse pas la flamme (§4.2)', () {
      final today = DateTime(2026, 7, 3); // vendredi
      final events = [
        StreakDay(date: DateTime(2026, 7, 1), type: StreakEventType.programRespected), // mer
        StreakDay(date: DateTime(2026, 7, 2), type: StreakEventType.restDay), // jeu
        StreakDay(date: DateTime(2026, 7, 3), type: StreakEventType.programRespected), // ven
      ];
      expect(service.programStreak(events, today: today), 3);
    });

    test('un programme manqué casse la flamme', () {
      final today = DateTime(2026, 7, 3);
      final events = [
        StreakDay(date: DateTime(2026, 7, 1), type: StreakEventType.programRespected),
        StreakDay(date: DateTime(2026, 7, 2), type: StreakEventType.programMissed),
        StreakDay(date: DateTime(2026, 7, 3), type: StreakEventType.programRespected),
      ];
      expect(service.programStreak(events, today: today), 1);
    });
  });

  group('activityStreak', () {
    test('compte les jours consécutifs avec activité', () {
      final today = DateTime(2026, 7, 3);
      final events = [
        StreakDay(date: DateTime(2026, 7, 1), type: StreakEventType.activity),
        StreakDay(date: DateTime(2026, 7, 2), type: StreakEventType.activity),
        StreakDay(date: DateTime(2026, 7, 3), type: StreakEventType.activity),
      ];
      expect(service.activityStreak(events, today: today), 3);
    });

    test('un trou remet la flamme à zéro', () {
      final today = DateTime(2026, 7, 3);
      final events = [
        StreakDay(date: DateTime(2026, 7, 1), type: StreakEventType.activity),
        // 2 juillet manquant
        StreakDay(date: DateTime(2026, 7, 3), type: StreakEventType.activity),
      ];
      expect(service.activityStreak(events, today: today), 1);
    });
  });
}
