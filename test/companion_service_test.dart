import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/companion/domain/companion_service.dart';

CompanionSnapshot snap({
  int activeDaysLast7 = 0,
  int sessionsLast7 = 0,
  int activitiesLast7 = 0,
  int activityStreak = 0,
  int programStreak = 0,
  bool trainedOrActiveToday = false,
  bool restPlannedToday = false,
  bool newRecordLast7 = false,
  int lifetimeSessions = 0,
  int lifetimeActivities = 0,
  int sessionsPerWeekGoal = 3,
}) =>
    CompanionSnapshot(
      activeDaysLast7: activeDaysLast7,
      sessionsLast7: sessionsLast7,
      activitiesLast7: activitiesLast7,
      activityStreak: activityStreak,
      programStreak: programStreak,
      trainedOrActiveToday: trainedOrActiveToday,
      restPlannedToday: restPlannedToday,
      newRecordLast7: newRecordLast7,
      lifetimeSessions: lifetimeSessions,
      lifetimeActivities: lifetimeActivities,
      sessionsPerWeekGoal: sessionsPerWeekGoal,
    );

void main() {
  const service = CompanionService();
  const messages = CompanionMessageService();

  group('énergie (§8.3)', () {
    test('0 jour actif = fatigué (pas puni)', () {
      expect(service.energyFor(0), CompanionEnergy.tired);
    });
    test('paliers', () {
      expect(service.energyFor(2), CompanionEnergy.normal);
      expect(service.energyFor(4), CompanionEnergy.motivated);
      expect(service.energyFor(5), CompanionEnergy.fit);
      expect(service.energyFor(7), CompanionEnergy.onFire);
    });
  });

  group('XP et niveaux (§9.1)', () {
    test('XP = séances×100 + activités×40 + bonus record', () {
      expect(service.xpFor(snap(lifetimeSessions: 2, lifetimeActivities: 3)),
          2 * 100 + 3 * 40);
      expect(
        service.xpFor(snap(lifetimeSessions: 1, newRecordLast7: true)),
        150,
      );
    });
    test('niveau croît avec l\'XP', () {
      expect(service.levelFor(0).level, 1);
      expect(service.levelFor(0).title, 'Étincelle');
      expect(service.levelFor(350).level, 2);
      expect(service.levelFor(4200).level, 6);
      expect(service.levelFor(4200).title, 'Coach intérieur');
    });
  });

  group('humeur', () {
    test('activité aujourd\'hui = boosté', () {
      expect(service.moodFor(snap(trainedOrActiveToday: true)),
          CompanionMood.boosted);
    });
    test('repos prévu = reposé', () {
      expect(service.moodFor(snap(restPlannedToday: true)),
          CompanionMood.rested);
    });
  });

  group('message du jour (§8.4, anti-culpabilisation)', () {
    test('repos prévu valorisé', () {
      final s = snap(restPlannedToday: true);
      final msg = messages.message(s, service.assess(s));
      expect(msg.toLowerCase(), contains('repos'));
    });
    test('inactivité -> propose une séance express, sans culpabiliser', () {
      final s = snap(sessionsLast7: 0, activitiesLast7: 0);
      final msg = messages.message(s, service.assess(s));
      expect(msg.toLowerCase(), contains('express'));
    });
    test('à une séance de la semaine complète', () {
      final s = snap(sessionsLast7: 2, activitiesLast7: 1, sessionsPerWeekGoal: 3);
      final msg = messages.message(s, service.assess(s));
      expect(msg, contains('une séance de terminer'));
    });
  });
}
