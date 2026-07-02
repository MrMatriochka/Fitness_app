import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Accès aux données du profil utilisateur et de ses mensurations (§11.1, §11.2).
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  /// Récupère le profil (unique en V1) s'il existe.
  Future<UserProfile?> getProfile() async {
    final rows = await _db.select(_db.userProfiles).get();
    return rows.isEmpty ? null : rows.first;
  }

  Stream<UserProfile?> watchProfile() {
    return _db.select(_db.userProfiles).watch().map(
          (rows) => rows.isEmpty ? null : rows.first,
        );
  }

  /// Crée le profil ou met à jour l'existant. Renvoie l'id du profil.
  Future<int> upsertProfile({
    int? id,
    required String name,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? level,
    String? mainGoal,
    String? equipment,
    int? sessionsPerWeekGoal,
  }) async {
    final now = DateTime.now();
    if (id == null) {
      return _db.into(_db.userProfiles).insert(
            UserProfilesCompanion.insert(
              name: Value(name),
              birthDate: Value(birthDate),
              heightCm: Value(heightCm),
              weightKg: Value(weightKg),
              level: Value(level),
              mainGoal: Value(mainGoal),
              equipment: Value(equipment),
              sessionsPerWeekGoal: Value(sessionsPerWeekGoal),
            ),
          );
    }
    await (_db.update(_db.userProfiles)..where((t) => t.id.equals(id))).write(
      UserProfilesCompanion(
        name: Value(name),
        birthDate: Value(birthDate),
        heightCm: Value(heightCm),
        weightKg: Value(weightKg),
        level: Value(level),
        mainGoal: Value(mainGoal),
        equipment: Value(equipment),
        sessionsPerWeekGoal: Value(sessionsPerWeekGoal),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  Future<List<BodyMeasurement>> getMeasurements(int profileId) {
    return (_db.select(_db.bodyMeasurements)
          ..where((t) => t.userProfileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<int> addMeasurement({
    required int profileId,
    required DateTime date,
    double? weightKg,
    double? chestCm,
    double? waistCm,
    double? armCm,
    double? thighCm,
    String? notes,
  }) {
    return _db.into(_db.bodyMeasurements).insert(
          BodyMeasurementsCompanion.insert(
            userProfileId: profileId,
            date: date,
            weightKg: Value(weightKg),
            chestCm: Value(chestCm),
            waistCm: Value(waistCm),
            armCm: Value(armCm),
            thighCm: Value(thighCm),
            notes: Value(notes),
          ),
        );
  }
}
