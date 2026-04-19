import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/medication_provider.dart';
import 'medication_plan_screen.dart';

/// Admin-Uebersicht: Liste aller Klienten + wie viele aktive
/// Medikamente sie haben. Tap oeffnet den Klient-Plan.
class MedicationPlanOverviewScreen extends ConsumerWidget {
  const MedicationPlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Client> clients = ref.watch(clientProvider);
    final medsAsync = ref.watch(allActiveMedicationsProvider);
    final theme = Theme.of(context);

    final meds = medsAsync.valueOrNull ?? const [];
    final perClient = <String, int>{};
    for (final m in meds) {
      perClient[m.clientId] = (perClient[m.clientId] ?? 0) + 1;
    }

    final sorted = [...clients]
      ..sort((a, b) =>
          (perClient[b.id] ?? 0).compareTo(perClient[a.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Medikationsplaene')),
      body: sorted.isEmpty
          ? const Center(child: Text('Keine Klienten vorhanden.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final c = sorted[i];
                final count = perClient[c.id] ?? 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: count > 0
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      child: Icon(Symbols.medication,
                          color: count > 0
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.outline),
                    ),
                    title: Text(c.fullName),
                    subtitle: Text(count == 0
                        ? 'Kein Plan'
                        : '$count aktive Medikament${count == 1 ? '' : 'e'}'),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MedicationPlanScreen(
                            clientId: c.id,
                            clientName: c.fullName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
