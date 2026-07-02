import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';

/// Onglet Profil (§8.7). Données physiques modifiables (R-008) et historique
/// des mesures corporelles (§6.3).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _goal = TextEditingController();
  int? _profileId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(profileRepositoryProvider).getProfile();
    if (!mounted) return;
    setState(() {
      _profileId = p?.id;
      _name.text = p?.name ?? '';
      _weight.text = p?.weightKg?.toString() ?? '';
      _height.text = p?.heightCm?.toString() ?? '';
      _goal.text = p?.mainGoal ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = await ref.read(profileRepositoryProvider).upsertProfile(
          id: _profileId,
          name: _name.text.trim().isEmpty ? 'Moi' : _name.text.trim(),
          weightKg: double.tryParse(_weight.text.replaceAll(',', '.')),
          heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
          mainGoal: _goal.text.trim().isEmpty ? null : _goal.text.trim(),
        );
    if (!mounted) return;
    setState(() => _profileId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil enregistré ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextFormField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                  validator: _optionalNumber,
                ),
                TextFormField(
                  controller: _height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Taille (cm)'),
                  validator: _optionalNumber,
                ),
                TextFormField(
                  controller: _goal,
                  decoration: const InputDecoration(labelText: 'Objectif principal'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Historique des mesures',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton.filledTonal(
                onPressed: _profileId == null ? null : _addMeasurement,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_profileId != null) _MeasurementsList(profileId: _profileId!),
        ],
      ),
    );
  }

  String? _optionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.replaceAll(',', '.')) == null
        ? 'Nombre invalide'
        : null;
  }

  Future<void> _addMeasurement() async {
    final controller = TextEditingController();
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle mesure de poids'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Poids (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (weight == null) return;
    await ref.read(profileRepositoryProvider).addMeasurement(
          profileId: _profileId!,
          date: DateTime.now(),
          weightKg: weight,
        );
    if (mounted) setState(() {});
  }
}

class _MeasurementsList extends ConsumerWidget {
  const _MeasurementsList({required this.profileId});
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<BodyMeasurement>>(
      future: ref.watch(profileRepositoryProvider).getMeasurements(profileId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const [];
        if (data.isEmpty) {
          return const Text('Aucune mesure enregistrée.');
        }
        return Column(
          children: [
            for (final m in data)
              ListTile(
                dense: true,
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('${m.weightKg ?? '-'} kg'),
                subtitle: Text(
                  '${m.date.day.toString().padLeft(2, '0')}/'
                  '${m.date.month.toString().padLeft(2, '0')}/${m.date.year}',
                ),
              ),
          ],
        );
      },
    );
  }
}
