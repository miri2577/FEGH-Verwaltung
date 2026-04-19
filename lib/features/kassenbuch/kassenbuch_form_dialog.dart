import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:signature/signature.dart';
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

  String? _belegBytesB64;
  String? _belegMimeType;
  String? _belegFileName;

  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    final e = widget.existing;
    if (e != null) {
      _datum = e.datum;
      _einzahlung = e.betrag >= 0;
      _betrag.text = e.betrag.abs().toStringAsFixed(2);
      _kategorie = e.kategorie;
      _beschreibung.text = e.beschreibung;
      _belegnummer.text = e.belegnummer ?? '';
      _confirm = e.confirmed;
      _belegBytesB64 = e.belegBytesB64;
      _belegMimeType = e.belegMimeType;
      _belegFileName = e.belegFileName;
    }
  }

  Future<void> _pickBeleg() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    const maxBytes = 5 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Datei zu gross (max. 5 MB).')),
      );
      return;
    }
    final ext = (file.extension ?? '').toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
    setState(() {
      _belegBytesB64 = base64Encode(bytes);
      _belegMimeType = mime;
      _belegFileName = file.name;
    });
  }

  void _clearBeleg() {
    setState(() {
      _belegBytesB64 = null;
      _belegMimeType = null;
      _belegFileName = null;
    });
  }

  @override
  void dispose() {
    _betrag.dispose();
    _beschreibung.dispose();
    _belegnummer.dispose();
    _signatureController.dispose();
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
              const SizedBox(height: 12),
              _belegSection(context, alreadyConfirmed),
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
                if (_confirm) ...[
                  const SizedBox(height: 8),
                  Text('Unterschrift (pflicht bei Freigabe):',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _signatureController.clear(),
                      icon: const Icon(Symbols.ink_eraser),
                      label: const Text('Loeschen'),
                    ),
                  ),
                ],
              ],
              if (alreadyConfirmed && widget.existing?.signaturePngB64 != null) ...[
                const SizedBox(height: 12),
                Text('Unterschrift:',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.memory(
                    base64Decode(widget.existing!.signaturePngB64!),
                    height: 120,
                    fit: BoxFit.contain,
                  ),
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

  Widget _belegSection(BuildContext context, bool alreadyConfirmed) {
    final theme = Theme.of(context);
    final hasBeleg = _belegBytesB64 != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _belegMimeType == 'application/pdf'
                    ? Symbols.picture_as_pdf
                    : Symbols.image,
                size: 18,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(hasBeleg ? 'Beleg angehaengt' : 'Beleg (Foto/PDF)',
                  style: theme.textTheme.labelLarge),
              const Spacer(),
              if (!alreadyConfirmed)
                TextButton.icon(
                  onPressed: _pickBeleg,
                  icon: Icon(hasBeleg ? Symbols.autorenew : Symbols.upload),
                  label: Text(hasBeleg ? 'Ersetzen' : 'Auswaehlen'),
                ),
              if (hasBeleg && !alreadyConfirmed)
                IconButton(
                  tooltip: 'Entfernen',
                  icon: const Icon(Symbols.close),
                  onPressed: _clearBeleg,
                ),
            ],
          ),
          if (hasBeleg) ...[
            const SizedBox(height: 6),
            Text(_belegFileName ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
            if (_belegMimeType?.startsWith('image/') == true) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(_belegBytesB64!),
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ] else if (_belegMimeType == 'application/pdf') ...[
              const SizedBox(height: 6),
              Text('PDF — Groesse: ${_belegSizeLabel()}',
                  style: theme.textTheme.bodySmall),
            ],
          ],
        ],
      ),
    );
  }

  String _belegSizeLabel() {
    if (_belegBytesB64 == null) return '–';
    final approxBytes = (_belegBytesB64!.length * 3) ~/ 4;
    if (approxBytes < 1024) return '$approxBytes B';
    if (approxBytes < 1024 * 1024) {
      return '${(approxBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(approxBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    if (_confirm && _signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bei Freigabe ist eine Unterschrift pflicht.')),
      );
      return;
    }
    setState(() => _submitting = true);
    String? sigB64 = widget.existing?.signaturePngB64;
    if (_confirm && _signatureController.isNotEmpty) {
      final bytes = await _signatureController.toPngBytes();
      if (bytes != null) sigB64 = base64Encode(bytes);
    }
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
      signaturePngB64: sigB64,
      belegBytesB64: _belegBytesB64,
      belegMimeType: _belegMimeType,
      belegFileName: _belegFileName,
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
