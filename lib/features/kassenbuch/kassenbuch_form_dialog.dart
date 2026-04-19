import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../models/kassenbuch_eintrag.dart';
import '../../providers/kassenbuch_provider.dart';
import '../../providers/settings_provider.dart';

class KassenbuchFormDialog extends ConsumerStatefulWidget {
  final String clientId;
  final KassenbuchEintrag? existing;

  const KassenbuchFormDialog({
    super.key,
    required this.clientId,
    this.existing,
  });

  @override
  ConsumerState<KassenbuchFormDialog> createState() =>
      _KassenbuchFormDialogState();
}

class _KassenbuchFormDialogState extends ConsumerState<KassenbuchFormDialog> {
  DateTime _datum = DateTime.now();
  bool _einzahlung = false;
  final _betrag = TextEditingController();
  KassenbuchKategorie _kategorie = KassenbuchKategorie.taschengeld;
  final _beschreibung = TextEditingController();
  final _belegnummer = TextEditingController();
  bool _confirm = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _datum = e.datum;
      _einzahlung = e.betrag >= 0;
      _betrag.text = e.betrag.abs().toStringAsFixed(2);
      _kategorie = e.kategorie;
      _beschreibung.text = e.beschreibung;
      _belegnummer.text = e.belegnummer ?? '';
      _confirm = e.confirmed;
    }
  }

  @override
  void dispose() {
    _betrag.dispose();
    _beschreibung.dispose();
    _belegnummer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final alreadyConfirmed = widget.existing?.confirmed ?? false;
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Kassenbuch-Eintrag'
          : alreadyConfirmed
              ? 'Eintrag (freigegeben)'
              : 'Eintrag bearbeiten'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alreadyConfirmed) ...[
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Symbols.lock),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Dieser Eintrag ist freigegeben und kann nicht mehr bearbeitet werden.',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                onTap: alreadyConfirmed ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    prefixIcon: Icon(Symbols.event),
                  ),
                  child: Text(df.format(_datum)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Auszahlung'),
                    selected: !_einzahlung,
                    onSelected: alreadyConfirmed
                        ? null
                        : (v) => setState(() => _einzahlung = !v),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Einzahlung'),
                    selected: _einzahlung,
                    onSelected: alreadyConfirmed
                        ? null
                        : (v) => setState(() => _einzahlung = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _betrag,
                enabled: !alreadyConfirmed,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Betrag (EUR)',
                  prefixIcon: Icon(Symbols.euro),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<KassenbuchKategorie>(
                value: _kategorie,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: KassenbuchKategorie.values
                    .map((k) =>
                        DropdownMenuItem(value: k, child: Text(k.label)))
                    .toList(),
                onChanged: alreadyConfirmed
                    ? null
                    : (v) => setState(() => _kategorie = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beschreibung,
                enabled: !alreadyConfirmed,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _belegnummer,
                enabled: !alreadyConfirmed,
                decoration: const InputDecoration(
                  labelText: 'Belegnummer (optional)',
                ),
              ),
              if (_kategorie == KassenbuchKategorie.gesundheit) ...[
                const SizedBox(height: 8),
                Text(
                  'Hinweis: Gesundheitsdetails nicht in die Beschreibung schreiben (Art. 9 DSGVO).',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11),
                ),
              ],
              if (!alreadyConfirmed) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _confirm,
                  onChanged: (v) => setState(() => _confirm = v),
                  title: const Text('Direkt freigeben'),
                  subtitle: const Text(
                      'Freigegebene Eintraege sind final — kein Update/Delete mehr.'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(alreadyConfirmed ? 'Schliessen' : 'Abbrechen'),
        ),
        if (!alreadyConfirmed)
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(widget.existing == null ? 'Buchen' : 'Speichern'),
          ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _datum = picked);
  }

  double _parseBetrag() {
    final v = _betrag.text.replaceAll(',', '.').trim();
    return double.tryParse(v) ?? 0;
  }

  Future<void> _submit() async {
    final betragAbs = _parseBetrag();
    if (betragAbs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gueltigen Betrag eingeben.')),
      );
      return;
    }
    if (_beschreibung.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beschreibung ist pflicht.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final settings = ref.read(appSettingsProvider);
    final employeeId = (settings.cloudUsername ?? '').toLowerCase();
    final now = DateTime.now();
    final e = KassenbuchEintrag(
      id: widget.existing?.id ?? const Uuid().v4(),
      clientId: widget.clientId,
      datum: _datum,
      betrag: _einzahlung ? betragAbs : -betragAbs,
      kategorie: _kategorie,
      beschreibung: _beschreibung.text.trim(),
      belegnummer:
          _belegnummer.text.trim().isEmpty ? null : _belegnummer.text.trim(),
      erfasstVonEmployeeId:
          employeeId.isEmpty ? null : employeeId,
      confirmed: _confirm,
      createdAt: widget.existing?.createdAt ?? now,
    );
    final notifier = ref.read(kassenbuchActionProvider.notifier);
    final ok = widget.existing == null
        ? await notifier.add(e)
        : await notifier.update(e);
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
