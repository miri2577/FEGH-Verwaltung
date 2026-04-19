import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../models/medication.dart';
import '../../providers/medication_provider.dart';

/// Dialog zum Anlegen / Bearbeiten eines Medikations-Plan-Eintrags.
class MedicationFormDialog extends ConsumerStatefulWidget {
  final String clientId;
  final Medication? existing;

  const MedicationFormDialog({
    super.key,
    required this.clientId,
    this.existing,
  });

  @override
  ConsumerState<MedicationFormDialog> createState() =>
      _MedicationFormDialogState();
}

class _MedicationFormDialogState extends ConsumerState<MedicationFormDialog> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _prescribedBy = TextEditingController();
  final _notes = TextEditingController();
  bool _morning = false;
  bool _noon = false;
  bool _evening = false;
  bool _night = false;
  DateTime _validFrom = DateTime.now();
  DateTime? _validUntil;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    if (m != null) {
      _name.text = m.name;
      _dosage.text = m.dosage;
      _prescribedBy.text = m.prescribedBy ?? '';
      _notes.text = m.notes ?? '';
      _morning = m.schedule.morning;
      _noon = m.schedule.noon;
      _evening = m.schedule.evening;
      _night = m.schedule.night;
      _validFrom = m.validFrom;
      _validUntil = m.validUntil;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _prescribedBy.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    return AlertDialog(
      title: Text(
          widget.existing == null ? 'Medikation hinzufuegen' : 'Medikation bearbeiten'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung',
                  hintText: 'z. B. Sertralin 50 mg',
                  prefixIcon: Icon(Symbols.pill),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dosage,
                decoration: const InputDecoration(
                  labelText: 'Dosis',
                  hintText: 'z. B. 1 Tablette',
                ),
              ),
              const SizedBox(height: 16),
              Text('Einnahmezeiten',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Morgens (08:00)'),
                    selected: _morning,
                    onSelected: (v) => setState(() => _morning = v),
                  ),
                  FilterChip(
                    label: const Text('Mittags (12:00)'),
                    selected: _noon,
                    onSelected: (v) => setState(() => _noon = v),
                  ),
                  FilterChip(
                    label: const Text('Abends (18:00)'),
                    selected: _evening,
                    onSelected: (v) => setState(() => _evening = v),
                  ),
                  FilterChip(
                    label: const Text('Nachts (22:00)'),
                    selected: _night,
                    onSelected: (v) => setState(() => _night = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickValidFrom,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Gueltig von',
                          prefixIcon: Icon(Symbols.event),
                        ),
                        child: Text(df.format(_validFrom)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickValidUntil,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Gueltig bis (optional)',
                          prefixIcon: Icon(Symbols.event),
                        ),
                        child: Text(
                            _validUntil == null ? '–' : df.format(_validUntil!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prescribedBy,
                decoration: const InputDecoration(
                  labelText: 'Verordnet von (optional)',
                  hintText: 'Arzt / Praxis',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notizen (optional)',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Symbols.warning,
                          color: Theme.of(context).colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dieses Modul dokumentiert nur Nicht-BTM. Fuer '
                          'Betaeubungsmittel ist ein separates BTM-Heft zu fuehren.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onTertiaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.existing == null ? 'Anlegen' : 'Speichern'),
        ),
      ],
    );
  }

  Future<void> _pickValidFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _validFrom = picked);
  }

  Future<void> _pickValidUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? _validFrom.add(const Duration(days: 30)),
      firstDate: _validFrom,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final dosage = _dosage.text.trim();
    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bezeichnung und Dosis sind pflicht.')),
      );
      return;
    }
    final schedule = MedicationSchedule(
      morning: _morning,
      noon: _noon,
      evening: _evening,
      night: _night,
    );
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens eine Einnahmezeit auswaehlen.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final existing = widget.existing;
    final medication = Medication(
      id: existing?.id ?? const Uuid().v4(),
      clientId: widget.clientId,
      name: name,
      dosage: dosage,
      schedule: schedule,
      validFrom: _validFrom,
      validUntil: _validUntil,
      prescribedBy: _prescribedBy.text.trim().isEmpty
          ? null
          : _prescribedBy.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      requiresBtmLog: false,
      active: existing?.active ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(medicationPlanActionProvider.notifier);
    final ok = existing == null
        ? await notifier.add(medication)
        : await notifier.update(medication);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speichern fehlgeschlagen.')),
      );
    }
  }
}
