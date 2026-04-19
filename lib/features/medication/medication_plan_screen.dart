import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/medication.dart';
import '../../providers/medication_provider.dart';
import 'medication_form_dialog.dart';

/// Medikationsplan eines einzelnen Klienten. Admin/Lead-Sicht.
class MedicationPlanScreen extends ConsumerWidget {
  final String clientId;
  final String? clientName;

  const MedicationPlanScreen({
    super.key,
    required this.clientId,
    this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final medsAsync = ref.watch(medicationsForClientProvider(clientId));
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(clientName == null
            ? 'Medikationsplan'
            : 'Medikationsplan – $clientName'),
        actions: [
          IconButton(
            tooltip: 'Medikation hinzufuegen',
            icon: const Icon(Symbols.add),
            onPressed: () => _openDialog(context, ref),
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (meds) {
          final active = meds.where((m) => m.active).toList();
          final inactive = meds.where((m) => !m.active).toList();
          if (meds.isEmpty) {
            return _empty(theme, () => _openDialog(context, ref));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Aktive Medikamente (${active.length})',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (active.isEmpty)
                Text('Aktuell kein aktives Medikament.',
                    style: TextStyle(color: theme.colorScheme.outline))
              else
                ...active.map((m) => _medCard(context, theme, ref, m, df)),
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Historie (${inactive.length})',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ...inactive.map((m) => _medCard(context, theme, ref, m, df)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty(ThemeData theme, VoidCallback onAdd) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.medication,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Noch kein Medikationsplan angelegt.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Symbols.add),
              label: const Text('Erste Medikation anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medCard(BuildContext context, ThemeData theme, WidgetRef ref,
      Medication m, DateFormat df) {
    final scheduleText = _scheduleText(m.schedule);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: m.active ? null : theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              m.active ? Symbols.medication : Symbols.medication_liquid,
              color: m.active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: m.active
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          )),
                      const SizedBox(width: 8),
                      Text(m.dosage,
                          style: TextStyle(color: theme.colorScheme.outline)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(scheduleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                  Text(
                    'Gueltig ${df.format(m.validFrom)}'
                    '${m.validUntil != null ? " bis ${df.format(m.validUntil!)}" : ""}'
                    '${m.prescribedBy != null ? "  |  Arzt: ${m.prescribedBy}" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Notiz: ${m.notes}', style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (m.active)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openDialog(context, ref, existing: m);
                  if (v == 'deactivate') _confirmDeactivate(context, ref, m);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                  PopupMenuItem(
                      value: 'deactivate', child: Text('Deaktivieren')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _scheduleText(MedicationSchedule s) {
    final parts = <String>[];
    if (s.morning) parts.add('M');
    if (s.noon) parts.add('T');
    if (s.evening) parts.add('A');
    if (s.night) parts.add('N');
    return parts.isEmpty
        ? 'Keine Einnahmezeit'
        : 'Einnahme: ${parts.join(' / ')}  (${s.dailyCount}x/Tag)';
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref,
      {Medication? existing}) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => MedicationFormDialog(
        clientId: clientId,
        existing: existing,
      ),
    );
  }

  Future<void> _confirmDeactivate(
      BuildContext context, WidgetRef ref, Medication m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medikation deaktivieren?'),
        content: Text(
            '"${m.name}" wird aus der aktiven Liste entfernt, die Historie bleibt erhalten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(medicationPlanActionProvider.notifier)
          .deactivate(m.id, m.clientId);
    }
  }
}
