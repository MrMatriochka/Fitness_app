import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/badge_service.dart';

/// Page des badges (extension §13 V2) : badges obtenus (colorés) et à débloquer
/// (grisés, avec progression).
class BadgesPage extends ConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes badges')),
      body: badges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (data) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${data.earned} / ${data.all.length} badges obtenus',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: data.all.length,
                itemBuilder: (context, i) => _BadgeCard(status: data.all[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.status});
  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final earned = status.earned;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: earned ? scheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: earned ? 1 : 0.35,
              child: Text(status.def.emoji,
                  style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 8),
            Text(
              status.def.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              status.def.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (earned)
              Text('✓ Obtenu',
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.bold))
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('${status.current} / ${status.def.target}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
