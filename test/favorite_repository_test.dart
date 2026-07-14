import 'package:drift/native.dart';
import 'package:fitness_app/core/database/app_database.dart';
import 'package:fitness_app/features/workouts/data/favorite_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FavoriteWorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FavoriteWorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('refuse un favori vide ou invalide', () {
    expect(
      () => repo.saveFavorite('', const [FavoriteItem(exerciseId: 1, sets: 3)]),
      throwsArgumentError,
    );
    expect(
      () => repo.saveFavorite('Vide', const []),
      throwsArgumentError,
    );
    expect(
      () => repo.saveFavorite(
        'Séries invalides',
        const [FavoriteItem(exerciseId: 1, sets: 0)],
      ),
      throwsArgumentError,
    );
  });

  test('sauvegarde un favori avec un nom nettoyé', () async {
    await repo.saveFavorite(
      '  Express  ',
      const [FavoriteItem(exerciseId: 1, sets: 3, reps: 12)],
    );

    final favorites = await repo.getAll();
    expect(favorites.single.name, 'Express');
    expect(repo.itemsOf(favorites.single).single.reps, 12);
  });
}
