import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:signature/signature.dart';

import '../../models/kassenbuch_eintrag.dart';
import '../../providers/kassenbuch_provider.dart';
import '../../providers/settings_provider.dart';

/// Storno-Dialog: erzeugt eine Gegenbuchung zu einem freigegebenen
/// Kassenbuch-Eintrag. Pflicht-Grund + Pflicht-Unterschrift.
class KassenbuchStornoDialog extends ConsumerStatefulWidget {
  final KassenbuchEintrag original;

  const KassenbuchStornoDialog({super.key, required this.original});

  @override
  ConsumerState<KassenbuchStornoDialog> createState() =>
      _KassenbuchStornoDialogState();
}

class _KassenbuchStornoDialogState
    extends ConsumerState<KassenbuchStornoDialog> {
  final _reason = TextEditingController();
  late final SignatureController _sig;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _sig = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _reason.dispose();
    _sig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final df = DateFormat('dd.MM.yyyy');
    final e = widget.original;
    return AlertDialog(
      title: const Text('Eintrag stornieren'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Symbols.receipt_long, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${df.format(e.datum)} · ${e.kategorie.label}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(e.beschreibung,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Betrag original: '
                        '${e.betrag >= 0 ? '+' : ''}${euro.format(e.betrag)}',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gegenbuchung wird erzeugt: '
                        '${-e.betrag >= 0 ? '+' : ''}${euro.format(-e.betrag)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Grund fuer Storno (pflicht)',
                  hintText: 'z. B. Falsche Kategorie, Doppelbuchung',
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
              const SizedBox(height: 8),
              Text(
                'Hinweis: Das Original bleibt im Kassenbuch erhalten, '
                'wird aber als "storniert" markiert. Die Stornobuchung '
                'ist selbst final.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
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
          icon: const Icon(Symbols.undo),
          label: const Text('Stornieren'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grund ist pflicht.')),
      );
      return;
    }
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
    final id = await ref.read(kassenbuchActionProvider.notifier).storno(
          widget.original.id,
          widget.original.clientId,
          employeeId: empId,
          reason: reason,
          signaturePngB64: sigB64,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (id != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stornobuchung erzeugt.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Storno fehlgeschlagen (bereits storniert oder nicht freigegeben).')),
      );
    }
  }
}
