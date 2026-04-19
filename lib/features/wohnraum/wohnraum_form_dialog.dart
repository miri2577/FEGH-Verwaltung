import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../models/wohnraum.dart';
import '../../providers/wohnraum_provider.dart';

class WohnraumFormDialog extends ConsumerStatefulWidget {
  final Wohnraum? existing;

  const WohnraumFormDialog({super.key, this.existing});

  @override
  ConsumerState<WohnraumFormDialog> createState() =>
      _WohnraumFormDialogState();
}

class _WohnraumFormDialogState extends ConsumerState<WohnraumFormDialog> {
  final _bezeichnung = TextEditingController();
  final _adresse = TextEditingController();
  final _kaltmiete = TextEditingController();
  final _nebenkosten = TextEditingController();
  final _kaution = TextEditingController();
  final _vermieter = TextEditingController();
  final _vertragsnummer = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _mietbeginn;
  DateTime? _mietende;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    if (w != null) {
      _bezeichnung.text = w.bezeichnung;
      _adresse.text = w.adresse ?? '';
      _kaltmiete.text = w.kaltmiete.toStringAsFixed(2);
      _nebenkosten.text = w.nebenkosten.toStringAsFixed(2);
      _kaution.text = w.kaution?.toStringAsFixed(2) ?? '';
      _vermieter.text = w.vermieter ?? '';
      _vertragsnummer.text = w.vertragsnummer ?? '';
      _notes.text = w.notes ?? '';
      _mietbeginn = w.mietbeginn;
      _mietende = w.mietende;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _bezeichnung,
      _adresse,
      _kaltmiete,
      _nebenkosten,
      _kaution,
      _vermieter,
      _vertragsnummer,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Wohnraum hinzufuegen'
          : 'Wohnraum bearbeiten'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _bezeichnung,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung',
                  hintText: 'z. B. Haus 1, Zimmer 3',
                  prefixIcon: Icon(Symbols.apartment),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _adresse,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optional)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kaltmiete,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kaltmiete (EUR/Monat)',
                        prefixIcon: Icon(Symbols.euro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nebenkosten,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nebenkosten (EUR/Monat)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kaution,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kaution (EUR, optional)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Mietbeginn',
                        ),
                        child: Text(
                            _mietbeginn != null ? df.format(_mietbeginn!) : '–'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Mietende',
                        ),
                        child: Text(
                            _mietende != null ? df.format(_mietende!) : '–'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vermieter,
                decoration: const InputDecoration(
                  labelText: 'Vermieter (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vertragsnummer,
                decoration: const InputDecoration(
                  labelText: 'Vertragsnummer (optional)',
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

  Future<void> _pickDate(bool beginn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (beginn ? _mietbeginn : _mietende) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (beginn) {
        _mietbeginn = picked;
      } else {
        _mietende = picked;
      }
    });
  }

  double _parseDouble(String v) {
    if (v.trim().isEmpty) return 0;
    return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  }

  Future<void> _submit() async {
    final b = _bezeichnung.text.trim();
    if (b.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bezeichnung ist pflicht.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final existing = widget.existing;
    final kaution = _kaution.text.trim().isEmpty ? null : _parseDouble(_kaution.text);
    final w = Wohnraum(
      id: existing?.id ?? const Uuid().v4(),
      clientId: existing?.clientId,
      bezeichnung: b,
      adresse: _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
      kaltmiete: _parseDouble(_kaltmiete.text),
      nebenkosten: _parseDouble(_nebenkosten.text),
      kaution: kaution,
      mietbeginn: _mietbeginn,
      mietende: _mietende,
      vermieter: _vermieter.text.trim().isEmpty ? null : _vermieter.text.trim(),
      vertragsnummer: _vertragsnummer.text.trim().isEmpty
          ? null
          : _vertragsnummer.text.trim(),
      status: existing?.status ?? WohnraumStatus.free,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final notifier = ref.read(wohnraumActionProvider.notifier);
    final ok =
        existing == null ? await notifier.add(w) : await notifier.update(w);
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
