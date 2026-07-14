import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Un exercice d'une séance rapide favorite (cibles sérialisées).
class FavoriteItem {
  const FavoriteItem({
    required this.exerciseId,
    required this.sets,
    this.reps,
    this.seconds,
    this.weightKg,
  });

  final int exerciseId;
  final int sets;
  final int? reps;
  final int? seconds;
  final double? weightKg;

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (seconds != null) 'seconds': seconds,
        if (weightKg != null) 'weightKg': weightKg,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
        exerciseId: (j['exerciseId'] as num).toInt(),
        sets: (j['sets'] as num).toInt(),
        reps: (j['reps'] as num?)?.toInt(),
        seconds: (j['seconds'] as num?)?.toInt(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
      );
}

/// Gestion des séances rapides favorites (extension §3.3, Épic 1).
class FavoriteWorkoutRepository {
  FavoriteWorkoutRepository(this._db);

  final AppDatabase _db;

  Future<int> saveFavorite(String name, List<FavoriteItem> items) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Le nom du favori est requis.');
    }
    if (items.isEmpty) {
      throw ArgumentError.value(
          items, 'items', 'Le favori doit contenir au moins un exercice.');
    }
    for (final item in items) {
      if (item.exerciseId <= 0) {
        throw ArgumentError.value(
            item.exerciseId, 'exerciseId', 'Identifiant exercice invalide.');
      }
      if (item.sets <= 0) {
        throw ArgumentError.value(
            item.sets, 'sets', 'Le nombre de séries doit être positif.');
      }
    }

    final payload = jsonEncode([for (final i in items) i.toJson()]);
    return _db.into(_db.favoriteWorkouts).insert(
          FavoriteWorkoutsCompanion.insert(
              name: trimmedName, payloadJson: payload),
        );
  }

  Future<List<FavoriteWorkout>> getAll() {
    return (_db.select(_db.favoriteWorkouts)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Décode le contenu d'un favori en liste d'items.
  List<FavoriteItem> itemsOf(FavoriteWorkout favorite) {
    final raw = jsonDecode(favorite.payloadJson) as List;
    return [
      for (final e in raw) _readItem((e as Map).cast<String, dynamic>()),
    ];
  }

  FavoriteItem _readItem(Map<String, dynamic> json) {
    final item = FavoriteItem.fromJson(json);
    if (item.exerciseId <= 0 || item.sets <= 0) {
      throw FormatException('Favori invalide', json);
    }
    return item;
  }

  Future<void> deleteFavorite(int id) {
    return (_db.delete(_db.favoriteWorkouts)..where((t) => t.id.equals(id)))
        .go();
  }
}
