import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/features/activities/domain/activity_impact_service.dart';

void main() {
  const service = ActivityImpactService();

  test('la course charge les jambes, pas le haut du corps', () {
    final load = service.loadForActivity(const ActivityImpactInput(
      sport: SportType.running,
      durationSeconds: 35 * 60,
      rpe: 7,
    ));
    expect(load['Legs'], greaterThan(0));
    expect(load.containsKey('Pull'), isFalse);
    expect(load.containsKey('Push'), isFalse);
  });

  test('l\'escalade charge surtout le Pull (avant-bras/dos)', () {
    final load = service.loadForActivity(const ActivityImpactInput(
      sport: SportType.climbing,
      durationSeconds: 90 * 60,
      rpe: 8,
    ));
    expect(load['Pull'], greaterThan(0));
    expect(load['Core'], greaterThan(0));
    expect((load['Pull'] ?? 0), greaterThan(load['Core'] ?? 0));
  });

  test('yoga / mobilité n\'ajoutent aucune fatigue (récup active)', () {
    expect(
      service.loadForActivity(const ActivityImpactInput(
        sport: SportType.yoga,
        durationSeconds: 20 * 60,
        rpe: 2,
      )),
      isEmpty,
    );
  });

  test('durée inconnue = pas de charge', () {
    expect(
      service.loadForActivity(const ActivityImpactInput(
        sport: SportType.running,
        durationSeconds: null,
        rpe: 7,
      )),
      isEmpty,
    );
  });

  test('un RPE plus élevé augmente la charge', () {
    final light = service.loadForActivity(const ActivityImpactInput(
      sport: SportType.cycling,
      durationSeconds: 60 * 60,
      rpe: 3,
    ));
    final hard = service.loadForActivity(const ActivityImpactInput(
      sport: SportType.cycling,
      durationSeconds: 60 * 60,
      rpe: 9,
    ));
    expect(hard['Legs'], greaterThan(light['Legs']!));
  });

  test('agrégation par groupe sur plusieurs activités', () {
    final load = service.loadByGroup(const [
      ActivityImpactInput(
          sport: SportType.running, durationSeconds: 30 * 60, rpe: 6),
      ActivityImpactInput(
          sport: SportType.climbing, durationSeconds: 60 * 60, rpe: 7),
    ]);
    expect(load['Legs'], greaterThan(0));
    expect(load['Pull'], greaterThan(0));
  });
}
