import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:uuid/uuid.dart';

import '../../models/btm_entry.dart';
import '../../models/client.dart';
import '../../models/employee.dart';
import '../../models/medication_administration.dart';
import '../../providers/client_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/btm_service.dart';

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

    final isBtm = slot.medication.requiresBtmLog;

    final confirmed = await showDialog<_GivenResult>(
      context: context,
      builder: (_) => _GivenDialog(
        medicationName: slot.medication.name,
        dosage: slot.medication.dosage,
        employeeName: employee.fullName,
        isBtm: isBtm,
      ),
    );
    if (confirmed == null) return;

    _BtmConfirmation? btm;
    if (isBtm) {
      if (!mounted) return;
      final lastStock = await BtmService()
          .letzterRestbestand(slot.medication.id);
      if (!mounted) return;
      btm = await showDialog<_BtmConfirmation>(
        context: context,
        builder: (_) => _BtmDialog(
          medicationName: slot.medication.name,
          defaultDosage: slot.medication.dosage,
          witnessCandidates: employees.where((e) => e.id != employee.id).toList(),
          previousStock: lastStock,
        ),
      );
      if (btm == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'BtM-Gabe abgebrochen — kein Zeuge oder Bestand erfasst.'),
        ));
        return;
      }
    }

    final ok = await ref
        .read(administrationActionProvider.notifier)
        .administer(slot, employeeId: employee.id, notes: confirmed.notes);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Speichern fehlgeschlagen.'),
      ));
      return;
    }

    if (btm != null) {
      final administrationId = slot.existing?.id ??
          '${slot.medicationId}-${slot.scheduledAt.toIso8601String()}';
      await BtmService().addEntry(BtmEntry(
        id: const Uuid().v4(),
        administrationId: administrationId,
        medicationId: slot.medication.id,
        clientId: slot.clientId,
        menge: btm.menge,
        restbestand: btm.restbestand,
        witnessEmployeeId: btm.witnessId,
        verordnenderArzt: slot.medication.prescribedBy,
        belegnummer: btm.belegnummer,
        notizen: btm.notizen,
        createdAt: DateTime.now(),
      ));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isBtm
          ? 'Gabe + BtM-Zusatzdokumentation gespeichert.'
          : 'Gabe quittiert.'),
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
  final bool isBtm;
  const _GivenDialog({
    required this.medicationName,
    required this.dosage,
    required this.employeeName,
    this.isBtm = false,
  });

  @override
  State<_GivenDialog> createState() => _GivenDialogState();
}

class _GivenDialogState extends State<_GivenDialog> {
  final _notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isBtm
          ? 'BtM-Gabe quittieren (Schritt 1/2)'
          : 'Gabe quittieren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medikament: ${widget.medicationName} (${widget.dosage})'),
          Text('Bestaetigt durch: ${widget.employeeName}'),
          if (widget.isBtm) ...[
            const SizedBox(height: 8),
            Text(
              'Im Anschluss: Zeuge und Restbestand (§13 BtMG).',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
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

class _BtmConfirmation {
  final String witnessId;
  final String menge;
  final double restbestand;
  final String? belegnummer;
  final String? notizen;
  _BtmConfirmation({
    required this.witnessId,
    required this.menge,
    required this.restbestand,
    this.belegnummer,
    this.notizen,
  });
}

class _BtmDialog extends StatefulWidget {
  final String medicationName;
  final String defaultDosage;
  final List<Employee> witnessCandidates;
  final double? previousStock;

  const _BtmDialog({
    required this.medicationName,
    required this.defaultDosage,
    required this.witnessCandidates,
    this.previousStock,
  });

  @override
  State<_BtmDialog> createState() => _BtmDialogState();
}

class _BtmDialogState extends State<_BtmDialog> {
  String? _witnessId;
  late final TextEditingController _menge =
      TextEditingController(text: widget.defaultDosage);
  late final TextEditingController _rest = TextEditingController(
      text: widget.previousStock?.toStringAsFixed(1) ?? '');
  final TextEditingController _beleg = TextEditingController();
  final TextEditingController _notizen = TextEditingController();

  @override
  void dispose() {
    _menge.dispose();
    _rest.dispose();
    _beleg.dispose();
    _notizen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('BtM-Zusatzprotokoll (Schritt 2/2)'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '§13 BtMG / BtMVV: Gabe nur mit Zeuge:in und aktualisierter '
                    'Bestandsangabe. Eintrag kann nach Speicherung nicht mehr '
                    'geaendert werden.',
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Medikament: ${widget.medicationName}',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _witnessId,
                decoration: const InputDecoration(
                  labelText: 'Zeuge:in (pflicht)',
                  prefixIcon: Icon(Symbols.group),
                ),
                items: widget.witnessCandidates
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.fullName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _witnessId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _menge,
                decoration: const InputDecoration(
                  labelText: 'Verabreichte Menge',
                  hintText: 'z. B. 1 Tablette, 5 ml',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rest,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Restbestand nach Gabe (pflicht)',
                  hintText: widget.previousStock != null
                      ? 'Vorher: ${widget.previousStock!.toStringAsFixed(1)}'
                      : 'z. B. 12',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beleg,
                decoration: const InputDecoration(
                  labelText: 'Belegnummer / Charge (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notizen,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notizen (optional)',
                  hintText: 'Beobachtung, vitale Zeichen',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            if (_witnessId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Zeuge:in ist pflicht.'),
              ));
              return;
            }
            final rest = double.tryParse(_rest.text.replaceAll(',', '.'));
            if (rest == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Restbestand muss eine Zahl sein.'),
              ));
              return;
            }
            Navigator.of(context).pop(_BtmConfirmation(
              witnessId: _witnessId!,
              menge: _menge.text.trim().isEmpty
                  ? widget.defaultDosage
                  : _menge.text.trim(),
              restbestand: rest,
              belegnummer: _beleg.text.trim().isEmpty ? null : _beleg.text.trim(),
              notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
            ));
          },
          child: const Text('BtM quittieren'),
        ),
      ],
    );
  }
}
