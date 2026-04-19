import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:signature/signature.dart';

import '../../providers/kassenbuch_provider.dart';
import '../../providers/settings_provider.dart';

/// Dialog zum Abschliessen eines Kassenbuch-Monats.
///
/// Voraussetzung: Alle Eintraege im Monat sind freigegeben. Der Abschluss
/// friert den Endsaldo ein, sperrt den Monat fuer neue Buchungen und
/// speichert eine Unterschrift.
class KassenbuchCloseMonthDialog extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const KassenbuchCloseMonthDialog({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<KassenbuchCloseMonthDialog> createState() =>
      _KassenbuchCloseMonthDialogState();
}

class _KassenbuchCloseMonthDialogState
    extends ConsumerState<KassenbuchCloseMonthDialog> {
  late int _year;
  late int _month;
  late final SignatureController _sig;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    _year = prev.year;
    _month = prev.month;
    _sig = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Monat abschliessen'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Klient: ${widget.clientName}',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Monat'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM', 'de_DE')
                                  .format(DateTime(2024, m))),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _month = v ?? _month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Jahr'),
                    items: List.generate(6, (i) => DateTime.now().year - 3 + i)
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Symbols.info, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nach dem Abschluss koennen im gewaehlten Monat keine '
                        'neuen Eintraege mehr gebucht werden. Korrekturen sind '
                        'nur ueber eine Stornobuchung im Folgemonat moeglich.',
                        style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text('Unterschrift (pflicht):',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Signature(
                  controller: _sig,
                  backgroundColor: Colors.white,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _sig.clear(),
                  icon: const Icon(Symbols.ink_eraser),
                  label: const Text('Loeschen'),
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
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Symbols.lock),
          label: const Text('Abschliessen'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_sig.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unterschrift ist pflicht.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final bytes = await _sig.toPngBytes();
    final sigB64 = bytes != null ? base64Encode(bytes) : null;
    final settings = ref.read(appSettingsProvider);
    final empId = (settings.cloudUsername ?? '').toLowerCase();
    final a = await ref.read(kassenbuchActionProvider.notifier).closeMonth(
          widget.clientId,
          DateTime(_year, _month, 1),
          employeeId: empId,
          signaturePngB64: sigB64,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (a != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Monat abgeschlossen — Endsaldo: '
                '${NumberFormat.currency(locale: 'de_DE', symbol: '€').format(a.saldoEnde)}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Abschluss fehlgeschlagen (Monat bereits geschlossen oder offene Eintraege).')),
      );
    }
  }
}
