import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/companion/domain/companion_xp_service.dart';

void main() {
  const service = CompanionXpService();

  test('XP par domaine selon le barème (§9)', () {
    const input = CompanionXpInput(
      strengthSessions: 3, // 300
      climbingSessions: 1, // 60
      personalRecords: 2, // 100  -> Force = 460
      cardioActivities: 4, // 200
      mobilityActivities: 2, // 80
      recoveryActivities: 1, // 30
      restDays: 3, // 60 -> Récup = 90
      programRespectedDays: 5, // 150
      distinctSports: 3, // 150
    );
    final map = service.byDomain(input);
    expect(map[CompanionDomain.force], 460);
    expect(map[CompanionDomain.cardio], 200);
    expect(map[CompanionDomain.mobility], 80);
    expect(map[CompanionDomain.recovery], 90);
    expect(map[CompanionDomain.regularity], 150);
    expect(map[CompanionDomain.exploration], 150);
  });

  test('total et domaine dominant', () {
    const input = CompanionXpInput(strengthSessions: 5, cardioActivities: 1);
    final r = service.compute(input);
    expect(r.total, 550);
    expect(r.dominant, CompanionDomain.force);
    expect(r.traitLabel, contains('Solide'));
  });

  test('cardio dominant -> énergique', () {
    const input = CompanionXpInput(cardioActivities: 10, strengthSessions: 1);
    expect(service.compute(input).dominant, CompanionDomain.cardio);
    expect(service.compute(input).traitLabel, contains('Énergique'));
  });

  test('aucune activité -> pas de dominant, trait "Nouveau"', () {
    final r = service.compute(const CompanionXpInput());
    expect(r.total, 0);
    expect(r.dominant, isNull);
    expect(r.traitLabel, contains('Nouveau'));
  });
}
