import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/medication.dart';
import '../../providers/employee_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/settings_provider.dart';
import 'med_pin_dialogs.dart';
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
              m.requiresBtmLog
                  ? Symbols.warning
                  : (m.active ? Symbols.medication : Symbols.medication_liquid),
              color: m.requiresBtmLog
                  ? theme.colorScheme.error
                  : (m.active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline),
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
                      if (m.requiresBtmLog) ...[
                        const SizedBox(width: 8),
                        _badge(theme, 'BtM',
                            theme.colorScheme.errorContainer,
                            theme.colorScheme.onErrorContainer),
                      ],
                      if (m.isPrn) ...[
                        const SizedBox(width: 8),
                        _badge(theme, 'PRN',
                            theme.colorScheme.tertiaryContainer,
                            theme.colorScheme.onTertiaryContainer),
                      ],
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
            if (m.active && m.isPrn)
              IconButton(
                tooltip: 'Bedarfsgabe erfassen',
                icon: const Icon(Symbols.bolt),
                onPressed: () => _prnAdminister(context, ref, m),
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

  Widget _badge(ThemeData theme, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _prnAdminister(
      BuildContext context, WidgetRef ref, Medication m) async {
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bedarfsgabe erfassen'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.name} · ${m.dosage}',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Grund (pflicht)',
                  hintText: 'z. B. Klient klagt ueber Kopfschmerzen',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Notizen (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Grund ist pflicht.'),
                ));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Gabe erfassen'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final settings = ref.read(appSettingsProvider);
    final employees = ref.read(employeesProvider).valueOrNull ?? const [];
    final me = settings.cloudUsername?.toLowerCase() ?? '';
    final emp = employees
        .cast<dynamic>()
        .firstWhere((e) => e.email.toLowerCase() == me, orElse: () => null);
    final empId = emp?.id ?? '';
    final empName = emp?.fullName as String? ?? empId;

    if (empId.isNotEmpty && context.mounted) {
      final pinOk = await promptMedPin(
        context,
        employeeId: empId,
        employeeName: empName,
      );
      if (!pinOk) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bedarfsgabe abgebrochen — PIN falsch.'),
        ));
        return;
      }
    }

    String? witnessId;
    if (m.effectiveRequiresWitness && context.mounted) {
      final candidates =
          employees.where((e) => e.id != empId).toList();
      final witness = await showDialog<dynamic>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Zeuge auswaehlen (Vier-Augen)'),
          children: candidates
              .map<Widget>((e) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(e),
                    child: Text('${e.fullName} (${e.email})'),
                  ))
              .toList(),
        ),
      );
      if (witness == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bedarfsgabe abgebrochen — Zeuge erforderlich.'),
        ));
        return;
      }
      witnessId = witness.id as String;
    }

    final service = ref.read(medicationAdministrationServiceProvider);
    final success = await service.administerPrn(
      m,
      employeeId: empId,
      witnessEmployeeId: witnessId,
      reason: reasonCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Bedarfsgabe quittiert.' : 'Speichern fehlgeschlagen.'),
    ));
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
