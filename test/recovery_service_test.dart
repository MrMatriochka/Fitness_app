import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/muscles/domain/recovery_service.dart';

void main() {
  const service = RecoveryService();
  const groups = ['Push', 'Pull', 'Legs', 'Core'];

  test('groupe très sollicité => fatigué, absent => frais', () {
    final statuses = service.assess(
      {'Push': 100, 'Core': 20},
      allGroups: groups,
    );
    expect(statuses['Push'], RecoveryStatus.fatigued);
    expect(statuses['Pull'], RecoveryStatus.fresh); // absent
    expect(statuses['Legs'], RecoveryStatus.fresh); // absent
  });

  test('recommandation cible les groupes frais', () {
    final statuses = service.assess(
      {'Push': 100},
      allGroups: groups,
    );
    final reco = service.recommendation(statuses);
    expect(reco, contains('Pull'));
    expect(reco, contains('Legs'));
  });

  test('sans données => message neutre', () {
    final statuses = service.assess({}, allGroups: groups);
    // tous frais
    expect(service.freshGroups(statuses).length, groups.length);
  });
}
