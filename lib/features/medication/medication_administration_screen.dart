import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/client.dart';
import '../../models/employee.dart';
import '../../models/medication_administration.dart';
import '../../providers/client_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/settings_provider.dart';

/// Hauptansicht fuer Mitarbeiter: heutige Medikationsgaben.
class MedicationAdministrationScreen extends ConsumerStatefulWidget {
  const MedicationAdministrationScreen({super.key});

  @override
  ConsumerState<MedicationAdministrationScreen> createState() =>
      _MedicationAdministrationScreenState();
}

class _MedicationAdministrationScreenState
    extends ConsumerState<MedicationAdministrationScreen> {
  DateTime _selectedDate = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotsAsync = ref.watch(todaysSlotsProvider(_selectedDate));
    final clients = ref.watch(clientProvider);
    final clientMap = {for (final c in clients) c.id: c};
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.valueOrNull ?? const [];

    final df = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
    final isToday = _selectedDate.isAtSameMomentAs(_today());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medikationsgaben'),
        actions: [
          IconButton(
            tooltip: 'Tag vorher',
            icon: const Icon(Symbols.chevron_left),
            onPressed: () => setState(() => _selectedDate =
                _selectedDate.subtract(const Duration(days: 1))),
          ),
          IconButton(
            tooltip: 'Heute',
            icon: const Icon(Symbols.today),
            onPressed: () => setState(() => _selectedDate = _today()),
          ),
          IconButton(
            tooltip: 'Tag nachher',
            icon: const Icon(Symbols.chevron_right),
            onPressed: () => setState(() => _selectedDate =
                _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(Symbols.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(df.format(_selectedDate),
                    style: theme.textTheme.titleMedium),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Heute'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (slots) {
                if (slots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.check_circle_outline,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('Keine geplanten Gaben fuer diesen Tag.'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _slotTile(
                    theme,
                    slots[i],
                    clientMap,
                    employees,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotTile(
    ThemeData theme,
    AdministrationSlot slot,
    Map<String, Client> clients,
    List<Employee> employees,
  ) {
    final clientName = clients[slot.clientId]?.fullName ?? slot.clientId;
    final time = DateFormat('HH:mm').format(slot.scheduledAt);
    final status = slot.status;
    final done = status != AdministrationStatus.pending;

    return Card(
      color: done ? theme.colorScheme.surfaceContainerLow : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Symbols.schedule,
                      color: theme.colorScheme.onPrimaryContainer),
                  Text(time,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clientName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${slot.medication.name}  |  ${slot.medication.dosage}',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  if (done) ...[
                    const SizedBox(height: 6),
                    _statusChip(theme, slot.existing!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!done)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Gegeben',
                    icon: const Icon(Symbols.check_circle, color: Colors.green),
                    onPressed: () =>
                        _handleGiven(slot, employees),
                  ),
                  IconButton(
                    tooltip: 'Verweigert',
                    icon: const Icon(Symbols.block, color: Colors.orange),
                    onPressed: () =>
                        _handleRefusedOrMissed(slot, employees, refused: true),
                  ),
                  IconButton(
                    tooltip: 'Verpasst',
                    icon: const Icon(Symbols.warning, color: Colors.red),
                    onPressed: () =>
                        _handleRefusedOrMissed(slot, employees, refused: false),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme, MedicationAdministration a) {
    Color bg;
    IconData icon;
    switch (a.status) {
      case AdministrationStatus.given:
        bg = Colors.green.shade100;
        icon = Symbols.check_circle;
        break;
      case AdministrationStatus.refused:
        bg = Colors.orange.shade100;
        icon = Symbols.block;
        break;
      case AdministrationStatus.missed:
        bg = Colors.red.shade100;
        icon = Symbols.warning;
        break;
      case AdministrationStatus.pending:
        bg = theme.colorScheme.surfaceContainerHigh;
        icon = Symbols.schedule;
    }
    final time = a.administeredAt == null
        ? ''
        : '  |  ${DateFormat('HH:mm').format(a.administeredAt!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(a.status.label + time, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ── Handler ────────────────────────────────────────────────────

  Future<void> _handleGiven(
      AdministrationSlot slot, List<Employee> employees) async {
    final employee = await _pickEmployee(employees);
    if (employee == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<_GivenResult>(
      context: context,
      builder: (_) => _GivenDialog(
        medicationName: slot.medication.name,
        dosage: slot.medication.dosage,
        employeeName: employee.fullName,
      ),
    );
    if (confirmed == null) return;

    final ok = await ref
        .read(administrationActionProvider.notifier)
        .administer(slot, employeeId: employee.id, notes: confirmed.notes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Gabe quittiert.' : 'Speichern fehlgeschlagen.'),
    ));
  }

  Future<void> _handleRefusedOrMissed(
      AdministrationSlot slot, List<Employee> employees,
      {required bool refused}) async {
    final employee = await _pickEmployee(employees);
    if (employee == null) return;
    if (!mounted) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReasonDialog(
        title: refused ? 'Gabe verweigert' : 'Gabe verpasst',
      ),
    );
    if (reason == null || reason.isEmpty) return;

    final notifier = ref.read(administrationActionProvider.notifier);
    final ok = refused
        ? await notifier.refuse(slot, employeeId: employee.id, reason: reason)
        : await notifier.miss(slot, employeeId: employee.id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Eintrag gespeichert.' : 'Speichern fehlgeschlagen.'),
    ));
  }

  /// Vorauswahl via `cloudUsername` → Mitarbeiter mit passender E-Mail.
  /// Fallback: Auswahl-Dialog.
  Future<Employee?> _pickEmployee(List<Employee> employees) async {
    final settings = ref.read(appSettingsProvider);
    final user = (settings.cloudUsername ?? '').toLowerCase();
    final preset = employees.cast<Employee?>().firstWhere(
      (e) => e != null && e.email.toLowerCase() == user,
      orElse: () => null,
    );
    if (preset != null) return preset;

    return showDialog<Employee?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Wer quittiert die Gabe?'),
        children: employees
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(e),
                  child: Text('${e.fullName} (${e.email})'),
                ))
            .toList(),
      ),
    );
  }
}

// ── Dialoge ──────────────────────────────────────────────────────

class _GivenResult {
  final String? notes;
  _GivenResult(this.notes);
}

class _GivenDialog extends StatefulWidget {
  final String medicationName;
  final String dosage;
  final String employeeName;
  const _GivenDialog({
    required this.medicationName,
    required this.dosage,
    required this.employeeName,
  });

  @override
  State<_GivenDialog> createState() => _GivenDialogState();
}

class _GivenDialogState extends State<_GivenDialog> {
  final _notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gabe quittieren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medikament: ${widget.medicationName} (${widget.dosage})'),
          Text('Bestaetigt durch: ${widget.employeeName}'),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration:
                const InputDecoration(labelText: 'Notizen (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(_GivenResult(_notes.text.trim())),
          icon: const Icon(Symbols.check_circle),
          label: const Text('Gegeben'),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  const _ReasonDialog({required this.title});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Grund (pflicht)',
          hintText: 'z. B. Klient abwesend / Klient verweigert',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty) return;
            Navigator.of(context).pop(r);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
