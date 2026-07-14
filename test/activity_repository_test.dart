import 'package:drift/native.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/core/database/app_database.dart';
import 'package:fitness_app/features/activities/data/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ActivityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('supprimer une activité garde les flammes des autres activités du jour',
      () async {
    final day = DateTime(2026, 7, 14, 10);
    final first = await repo.logActivity(
      date: day,
      type: ActivityType.sportActivity,
      sportType: SportType.running,
      durationSeconds: 1800,
    );
    await repo.logActivity(
      date: day.add(const Duration(hours: 3)),
      type: ActivityType.sportActivity,
      sportType: SportType.swimming,
      durationSeconds: 1200,
    );

    expect(await db.select(db.streakEvents).get(), hasLength(2));

    await repo.deleteActivity(first);

    final remainingEvents = await db.select(db.streakEvents).get();
    expect(remainingEvents, hasLength(1));
    expect(remainingEvents.single.source, isNot('activity:$first'));
  });
}
