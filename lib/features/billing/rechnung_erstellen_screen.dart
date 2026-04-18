import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/billing_provider.dart';
import '../../services/billing_service.dart';

/// Erstellt eine neue Rechnung mit manueller Positions-Eingabe.
///
/// Aehnlich zur Doku-App, aber ohne automatische Aggregation aus
/// Appointments - die Verwaltung laesst den Admin frei Positionen
/// eintippen (fuer Monats-Sammelrechnungen, Einzelabrechnungen etc.).
class RechnungErstellenScreen extends ConsumerStatefulWidget {
  const RechnungErstellenScreen({super.key});

  @override
  ConsumerState<RechnungErstellenScreen> createState() =>
      _RechnungErstellenScreenState();
}

class _RechnungErstellenScreenState
    extends ConsumerState<RechnungErstellenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rechnungsnummerCtrl = TextEditingController();
  final _bestellnummerCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();

  DateTime _rechnungsdatum = DateTime.now();
  DateTime? _leistungsVon;
  DateTime? _leistungsBis;
  String? _empfaengerId;
  int _zahlungszielTage = 30;
  UstBefreiungsgrund _ustBefreiung = UstBefreiungsgrund.par4Nr16h;

  final List<_PositionData> _positionen = [];

  @override
  void initState() {
    super.initState();
    _loadNextNumber();
    _addLeerePosition();
  }

  Future<void> _loadNextNumber() async {
    final svc = ref.read(billingServiceProvider);
    final nr = await svc.nextRechnungsnummer();
    if (mounted) {
      setState(() => _rechnungsnummerCtrl.text = nr);
    }
  }

  @override
  void dispose() {
    _rechnungsnummerCtrl.dispose();
    _bestellnummerCtrl.dispose();
    _bemerkungCtrl.dispose();
    for (final p in _positionen) {
      p.dispose();
    }
    super.dispose();
  }

  void _addLeerePosition() {
    setState(() => _positionen.add(_PositionData()));
  }

  void _removePosition(int i) {
    setState(() {
      _positionen[i].dispose();
      _positionen.removeAt(i);
    });
  }

  double get _gesamtNetto => _positionen.fold(0.0, (s, p) => s + p.netto);
  double get _gesamtBrutto => _positionen.fold(0.0, (s, p) => s + p.brutto);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_empfaengerId == null) {
      _showError('Bitte Empfaenger auswaehlen');
      return;
    }
    if (_positionen.isEmpty) {
      _showError('Mindestens eine Position erforderlich');
      return;
    }

    final positionen = _positionen
        .map((p) => RechnungsPosition.create(
              bezeichnung: p.bezeichnungCtrl.text.trim(),
              menge: double.tryParse(p.mengeCtrl.text.replaceAll(',', '.')) ?? 0,
              einheit: p.einheitCtrl.text.trim(),
              einzelpreis:
                  double.tryParse(p.einzelpreisCtrl.text.replaceAll(',', '.')) ??
                      0,
              steuerprozent:
                  double.tryParse(p.steuerCtrl.text.replaceAll(',', '.')) ?? 0,
              hinweis: p.hinweisCtrl.text.trim().isEmpty
                  ? null
                  : p.hinweisCtrl.text.trim(),
            ))
        .toList();

    final rechnung = Rechnung.create(
      rechnungsnummer: _rechnungsnummerCtrl.text.trim(),
      rechnungsdatum: _rechnungsdatum,
      leistungsVon: _leistungsVon,
      leistungsBis: _leistungsBis,
      empfaengerId: _empfaengerId!,
      positionen: positionen,
      zahlungszielTage: _zahlungszielTage,
      bestellnummer: _bestellnummerCtrl.text.trim().isEmpty
          ? null
          : _bestellnummerCtrl.text.trim(),
      bemerkung: _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim(),
      ustBefreiung: _ustBefreiung,
    );

    final ok = await ref.read(rechnungenProvider.notifier).add(rechnung);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rechnung ${rechnung.rechnungsnummer} erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError('Speichern fehlgeschlagen');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final empfaenger = ref.watch(empfaengerProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Rechnung'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kopfdaten
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rechnungsnummerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rechnungsnummer *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Pflicht' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _rechnungsdatum,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (d != null) setState(() => _rechnungsdatum = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Rechnungsdatum',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(df.format(_rechnungsdatum)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _empfaengerId,
              decoration: const InputDecoration(
                labelText: 'Empfaenger *',
                border: OutlineInputBorder(),
              ),
              items: empfaenger
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _empfaengerId = v),
              validator: (v) => v == null ? 'Bitte auswaehlen' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _leistungsVon ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _leistungsVon = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Leistung von',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_leistungsVon != null
                          ? df.format(_leistungsVon!)
                          : '-'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _leistungsBis ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _leistungsBis = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Leistung bis',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_leistungsBis != null
                          ? df.format(_leistungsBis!)
                          : '-'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UstBefreiungsgrund>(
              initialValue: _ustBefreiung,
              decoration: const InputDecoration(
                labelText: 'Steuerbefreiung',
                border: OutlineInputBorder(),
              ),
              items: UstBefreiungsgrund.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.anzeigeText),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _ustBefreiung = v ?? UstBefreiungsgrund.keine),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bestellnummerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bestell-/Aktenzeichen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: _zahlungszielTage.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Zahlungsziel (Tage)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _zahlungszielTage = int.tryParse(v) ?? 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Positionen
            Row(
              children: [
                const Text('Positionen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addLeerePosition,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Position hinzufuegen'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _positionen.length; i++)
              _PositionCard(
                index: i,
                data: _positionen[i],
                onChanged: () => setState(() {}),
                onRemove: () => _removePosition(i),
              ),
            const SizedBox(height: 16),
            // Summe
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Gesamt netto:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('${_gesamtNetto.toStringAsFixed(2)} EUR'),
                    const Spacer(),
                    const Text('Brutto:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('${_gesamtBrutto.toStringAsFixed(2)} EUR',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bemerkungCtrl,
              decoration: const InputDecoration(
                labelText: 'Bemerkung',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionData {
  final bezeichnungCtrl = TextEditingController();
  final mengeCtrl = TextEditingController(text: '1');
  final einheitCtrl = TextEditingController(text: 'Stunde');
  final einzelpreisCtrl = TextEditingController();
  final steuerCtrl = TextEditingController(text: '0');
  final hinweisCtrl = TextEditingController();

  double get netto {
    final m = double.tryParse(mengeCtrl.text.replaceAll(',', '.')) ?? 0;
    final e = double.tryParse(einzelpreisCtrl.text.replaceAll(',', '.')) ?? 0;
    return m * e;
  }

  double get brutto {
    final n = netto;
    final s = double.tryParse(steuerCtrl.text.replaceAll(',', '.')) ?? 0;
    return n + n * s / 100.0;
  }

  void dispose() {
    bezeichnungCtrl.dispose();
    mengeCtrl.dispose();
    einheitCtrl.dispose();
    einzelpreisCtrl.dispose();
    steuerCtrl.dispose();
    hinweisCtrl.dispose();
  }
}

class _PositionCard extends StatelessWidget {
  final int index;
  final _PositionData data;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PositionCard({
    required this.index,
    required this.data,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Position ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: data.bezeichnungCtrl,
              decoration: const InputDecoration(
                labelText: 'Bezeichnung',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: data.mengeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Menge',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: data.einheitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Einheit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: data.einzelpreisCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preis (EUR)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: data.steuerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'USt %',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const Spacer(),
                Text('${data.netto.toStringAsFixed(2)} EUR',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: data.hinweisCtrl,
              decoration: const InputDecoration(
                labelText: 'Hinweis / Beschreibung (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
