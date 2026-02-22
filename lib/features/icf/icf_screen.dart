import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/policy_provider.dart';

class ICFScreen extends ConsumerWidget {
  const ICFScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(policyProvider);
    final allowed = policy.canViewDocumentation();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.health_and_safety,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'ICF-Klassifikation & TIB',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: allowed ? () {} : null,
                  icon: const Icon(Symbols.add_circle, size: 18),
                  label: const Text('Neue Bedarfsermittlung'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: allowed
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.construction,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ICF-Klassifikation & TIB',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Berliner TIB-System wird implementiert...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.lock, size: 64, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Kein Zugriff auf Dokumentation', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('Nur Team‑Leitung darf ICF/TIB einsehen.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
