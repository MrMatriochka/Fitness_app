import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/companion/domain/badge_service.dart';

void main() {
  const service = BadgeService();

  test('aucun badge au départ', () {
    expect(service.earnedCount(const BadgeStats()), 0);
  });

  test('première séance débloque un badge', () {
    final earned = service
        .evaluate(const BadgeStats(totalSessions: 1))
        .where((b) => b.earned)
        .map((b) => b.def.id);
    expect(earned, contains('first_session'));
  });

  test('paliers de séances', () {
    expect(service.earnedCount(const BadgeStats(totalSessions: 10)),
        2); // first_session + sessions_10
    expect(
      service
          .evaluate(const BadgeStats(totalSessions: 50))
          .where((b) => b.earned)
          .map((b) => b.def.id),
      containsAll(['first_session', 'sessions_10', 'sessions_50']),
    );
  });

  test('le repos est récompensé (anti-culpabilisation)', () {
    final earned = service
        .evaluate(const BadgeStats(restDays: 5))
        .where((b) => b.earned)
        .map((b) => b.def.id);
    expect(earned, contains('rest_5'));
  });

  test('progression d\'un badge non obtenu', () {
    final status = service
        .evaluate(const BadgeStats(distinctSports: 2))
        .firstWhere((b) => b.def.id == 'sports_3');
    expect(status.earned, isFalse);
    expect(status.progress, closeTo(2 / 3, 0.001));
  });

  test('progression bornée à 1', () {
    final status = service
        .evaluate(const BadgeStats(totalSessions: 999))
        .firstWhere((b) => b.def.id == 'first_session');
    expect(status.progress, 1);
  });
}
