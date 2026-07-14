import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../domain/activity_service.dart';

/// Une métrique flexible saisie pour une activité (clé/valeur/unité).
class ActivityMetricInput {
  const ActivityMetricInput(this.key, this.value, {this.unit});

  final String key;
  final String value;
  final String? unit;
}

/// Résultat de lecture : une activité + ses métriques.
class ActivityWithMetrics {
  const ActivityWithMetrics(this.log, this.metrics);

  final ActivityLog log;
  final List<ActivityMetric> metrics;
}

/// Journal d'activité global (extension §7, §11) : enregistre les activités
/// (séances rapides, sports externes, mobilité, récupération), génère la flamme
/// activité et estime les calories. Ne valide jamais une séance prévue (§12).
class ActivityRepository {
  ActivityRepository(this._db,
      {ActivityService activityService = const ActivityService()})
      : _service = activityService;

  final AppDatabase _db;
  final ActivityService _service;

  /// Enregistre une activité et sa flamme activité. Renvoie l'id de l'activité.
  ///
  /// [weightKg] (profil) sert à l'estimation calorique ; si absent, calories
  /// laissées à null. [countsAsBonus] ajoute une flamme bonus (§6, §12).
  Future<int> logActivity({
    required DateTime date,
    required ActivityType type,
    SportType? sportType,
    String source = 'manual',
    int? durationSeconds,
    int? rpe,
    Intensity? intensity,
    double? weightKg,
    String? notes,
    String? place,
    int? linkedWorkoutSessionId,
    List<ActivityMetricInput> metrics = const [],
    bool countsAsActivity = true,
    bool countsAsBonus = false,
  }) async {
    final calories = _service.estimateCalories(
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      intensity: intensity,
      rpe: rpe,
    );
    final resolvedIntensity =
        _service.resolveIntensity(label: intensity, rpe: rpe);

    return _db.transaction(() async {
      final logId = await _db.into(_db.activityLogs).insert(
            ActivityLogsCompanion.insert(
              date: date,
              type: type.name,
              sportType: Value(sportType?.name),
              source: Value(source),
              durationSeconds: Value(durationSeconds),
              rpe: Value(rpe),
              intensityLabel: Value(resolvedIntensity.name),
              caloriesEstimated: Value(calories > 0 ? calories : null),
              notes: Value(notes),
              place: Value(place),
              linkedWorkoutSessionId: Value(linkedWorkoutSessionId),
            ),
          );

      for (final m in metrics) {
        await _db.into(_db.activityMetrics).insert(
              ActivityMetricsCompanion.insert(
                activityLogId: logId,
                metricKey: m.key,
                value: m.value,
                unit: Value(m.unit),
              ),
            );
      }

      if (countsAsActivity) {
        await _db.into(_db.streakEvents).insert(
              StreakEventsCompanion.insert(
                date: date,
                type: StreakEventType.activity.name,
                source: const Value('activity'),
              ),
            );
      }
      if (countsAsBonus) {
        await _db.into(_db.streakEvents).insert(
              StreakEventsCompanion.insert(
                date: date,
                type: StreakEventType.bonus.name,
                source: const Value('activity'),
              ),
            );
      }

      return logId;
    });
  }

  /// Activités entre [start] (inclus) et [end] (exclu), plus récentes d'abord.
  Future<List<ActivityLog>> activitiesBetween(
      DateTime start, DateTime end) {
    return (_db.select(_db.activityLogs)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Nombre total d'activités enregistrées (pour l'XP du compagnon).
  Future<int> activityCount() async {
    final rows = await _db.select(_db.activityLogs).get();
    return rows.length;
  }

  /// Les [limit] dernières activités enregistrées.
  Future<List<ActivityLog>> recentActivities({int limit = 20}) {
    return (_db.select(_db.activityLogs)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  /// Métriques d'une activité donnée.
  Future<List<ActivityMetric>> metricsFor(int activityLogId) {
    return (_db.select(_db.activityMetrics)
          ..where((t) => t.activityLogId.equals(activityLogId)))
        .get();
  }

  /// Une activité avec ses métriques, ou null.
  Future<ActivityWithMetrics?> byId(int id) async {
    final log = await (_db.select(_db.activityLogs)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (log == null) return null;
    return ActivityWithMetrics(log, await metricsFor(id));
  }

  /// Supprime une activité (et ses métriques, via cascade) ainsi que les
  /// flammes générées le même jour par une activité.
  Future<void> deleteActivity(int id) async {
    await _db.transaction(() async {
      final log = await (_db.select(_db.activityLogs)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      await (_db.delete(_db.activityLogs)..where((t) => t.id.equals(id))).go();
      if (log != null) {
        final dayStart = DateTime(log.date.year, log.date.month, log.date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        await (_db.delete(_db.streakEvents)
              ..where((t) =>
                  t.source.equals('activity') &
                  t.date.isBiggerOrEqualValue(dayStart) &
                  t.date.isSmallerThanValue(dayEnd)))
            .go();
      }
    });
  }
}
