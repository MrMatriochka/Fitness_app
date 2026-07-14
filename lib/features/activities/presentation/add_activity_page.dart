import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../data/activity_repository.dart';
import 'activity_labels.dart';

/// Description d'un champ de métrique propre à un sport (§5).
class _MetricField {
  const _MetricField(this.key, this.label, {this.unit, this.numeric = true});
  final String key;
  final String label;
  final String? unit;
  final bool numeric;
}

/// Métriques proposées selon le sport (§5.1 → §5.7). Toutes optionnelles.
List<_MetricField> _metricsFor(SportType sport) {
  switch (sport) {
    case SportType.running:
      return const [
        _MetricField('distance', 'Distance', unit: 'km'),
        _MetricField('elevation', 'Dénivelé', unit: 'm'),
        _MetricField('pace', 'Allure moyenne', unit: 'min/km', numeric: false),
      ];
    case SportType.swimming:
      return const [
        _MetricField('distance', 'Distance', unit: 'm'),
        _MetricField('laps', 'Longueurs'),
        _MetricField('stroke', 'Type de nage', numeric: false),
      ];
    case SportType.climbing:
      return const [
        _MetricField('climb_type', 'Type (bloc / voie)', numeric: false),
        _MetricField('attempts', 'Essais'),
        _MetricField('successes', 'Réussis'),
        _MetricField('max_grade', 'Niveau max', numeric: false),
        _MetricField('fatigue_forearm', 'Fatigue avant-bras', unit: '/10'),
        _MetricField('fatigue_fingers', 'Fatigue doigts', unit: '/10'),
      ];
    case SportType.cycling:
      return const [
        _MetricField('distance', 'Distance', unit: 'km'),
        _MetricField('elevation', 'Dénivelé', unit: 'm'),
        _MetricField('avg_speed', 'Vitesse moyenne', unit: 'km/h'),
      ];
    case SportType.walking:
    case SportType.hiking:
      return const [
        _MetricField('distance', 'Distance', unit: 'km'),
        _MetricField('steps', 'Pas'),
        _MetricField('elevation', 'Dénivelé', unit: 'm'),
      ];
    case SportType.yoga:
    case SportType.mobility:
      return const [
        _MetricField('zones', 'Zones travaillées', numeric: false),
      ];
    case SportType.football:
    case SportType.padel:
      return const [
        _MetricField('match_type', 'Type (match / entraînement)',
            numeric: false),
        _MetricField('fatigue_legs', 'Fatigue jambes', unit: '/10'),
        _MetricField('fatigue_cardio', 'Fatigue cardio', unit: '/10'),
      ];
    case SportType.other:
      return const [];
  }
}

/// Formulaire d'ajout d'une activité physique (extension §4, Épic 2).
class AddActivityPage extends ConsumerStatefulWidget {
  const AddActivityPage({super.key});

  @override
  ConsumerState<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends ConsumerState<AddActivityPage> {
  SportType _sport = SportType.running;
  DateTime _date = DateTime.now();
  final _durationMin = TextEditingController();
  final _notes = TextEditingController();
  final _place = TextEditingController();
  double _rpe = 5;
  bool _countsAsBonus = false;
  bool _saving = false;

  /// Contrôleurs de métriques, créés à la demande et conservés par clé.
  final Map<String, TextEditingController> _metricControllers = {};

  TextEditingController _metricController(String key) =>
      _metricControllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    _durationMin.dispose();
    _notes.dispose();
    _place.dispose();
    for (final c in _metricControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Une activité de mobilité / yoga est classée comme telle (utile pour la
  /// récupération active, §6), les autres sports comme activité sportive.
  ActivityType get _activityType =>
      (_sport == SportType.yoga || _sport == SportType.mobility)
          ? ActivityType.mobility
          : ActivityType.sportActivity;

  int? get _durationSeconds {
    final min = int.tryParse(_durationMin.text.trim());
    if (min == null || min <= 0) return null;
    return min * 60;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final weight = profile?.weightKg;
    final kcal = ref.read(activityServiceProvider).estimateCalories(
          durationSeconds: _durationSeconds,
          weightKg: weight,
          rpe: _rpe.round(),
        );
    final metrics = _metricsFor(_sport);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une activité')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          DropdownButtonFormField<SportType>(
            initialValue: _sport,
            decoration: const InputDecoration(
              labelText: 'Sport',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in SportType.values)
                DropdownMenuItem(
                  value: s,
                  child: Text('${sportEmoji(s)}  ${sportLabel(s)}'),
                ),
            ],
            onChanged: (v) => setState(() => _sport = v ?? SportType.running),
          ),
          const SizedBox(height: 16),
          _DateField(
            date: _date,
            onPick: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationMin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Durée',
              suffixText: 'min',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Intensité ressentie (RPE) : ${_rpe.round()}/10',
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: _rpe,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_rpe.round()}',
            onChanged: (v) => setState(() => _rpe = v),
          ),
          Text(rpeHint(_rpe.round()),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (metrics.isNotEmpty) ...[
            Text('Métriques ${sportLabel(_sport).toLowerCase()}',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final m in metrics) ...[
              TextField(
                controller: _metricController(m.key),
                keyboardType: m.numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: m.label,
                  suffixText: m.unit,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
          ],
          TextField(
            controller: _place,
            decoration: const InputDecoration(
              labelText: 'Lieu (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (sensations, douleur, contexte)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _countsAsBonus,
            onChanged: (v) => setState(() => _countsAsBonus = v),
            title: const Text('Compter comme activité bonus'),
            subtitle: const Text('Ajoute une flamme bonus ✨ à cette journée.'),
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      weight == null
                          ? 'Renseigne ton poids dans le Profil pour estimer '
                              'les calories.'
                          : _durationSeconds == null
                              ? 'Indique une durée pour estimer les calories.'
                              : 'Calories estimées : ${kcal.round()} kcal',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer l\'activité'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_durationSeconds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique une durée (en minutes).')),
      );
      return;
    }
    setState(() => _saving = true);

    final metrics = <ActivityMetricInput>[];
    for (final m in _metricsFor(_sport)) {
      final raw = _metricControllers[m.key]?.text.trim() ?? '';
      if (raw.isNotEmpty) {
        metrics.add(ActivityMetricInput(m.key, raw, unit: m.unit));
      }
    }

    final weight = ref.read(profileProvider).valueOrNull?.weightKg;
    await ref.read(activityRepositoryProvider).logActivity(
          date: _date,
          type: _activityType,
          sportType: _sport,
          durationSeconds: _durationSeconds,
          rpe: _rpe.round(),
          weightKg: weight,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          place: _place.text.trim().isEmpty ? null : _place.text.trim(),
          metrics: metrics,
          countsAsBonus: _countsAsBonus,
        );

    if (!mounted) return;
    invalidateSessionData(ref);
    Navigator.of(context).pop(true);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onPick});
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(now.year - 2),
          lastDate: now,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
      ),
    );
  }
}
