import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:signature/signature.dart';

import '../../models/btm_destruction.dart';
import '../../models/employee.dart';
import '../../models/medication.dart';
import '../../providers/employee_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/btm_service.dart';

/// BtM-Bestandsliste pro Einrichtung mit Vernichtungsprotokoll.
class BtmStockScreen extends ConsumerStatefulWidget {
  const BtmStockScreen({super.key});

  @override
  ConsumerState<BtmStockScreen> createState() => _BtmStockScreenState();
}

class _BtmStockScreenState extends ConsumerState<BtmStockScreen> {
  final _btm = BtmService();
  late Future<List<BtmStockRow>> _stockFuture;

  @override
  void initState() {
    super.initState();
    _stockFuture = _btm.stockOverview();
  }

  Future<void> _refresh() async {
    setState(() => _stockFuture = _btm.stockOverview());
    await _stockFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medsAsync = ref.watch(allActiveMedicationsProvider);
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('BtM-Bestand'),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Symbols.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (meds) {
          final btmMeds =
              meds.where((m) => m.requiresBtmLog).toList();
          final medById = {for (final m in btmMeds) m.id: m};
          return FutureBuilder<List<BtmStockRow>>(
            future: _stockFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data ?? const [];
              if (btmMeds.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.medication,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text(
                            'Keine BtM-Verordnungen angelegt.'),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: btmMeds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final m = btmMeds[i];
                  final row = rows.where((r) => r.medicationId == m.id)
                      .cast<BtmStockRow?>()
                      .firstWhere((_) => true, orElse: () => null);
                  return _stockTile(theme, m, row, medById, df);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _stockTile(ThemeData theme, Medication m, BtmStockRow? row,
      Map<String, Medication> medById, DateFormat df) {
    final stock = row?.stock ?? 0;
    final low = stock <= 0 ? theme.colorScheme.error : null;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(Symbols.warning,
              color: theme.colorScheme.onErrorContainer),
        ),
        title: Text('${m.name}  ·  ${m.dosage}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bestand: ${stock.toStringAsFixed(2)}'
                '${row?.unit.isNotEmpty == true ? ' ${row!.unit}' : ''}'),
            if (row != null)
              Text('Letzte Buchung: ${df.format(row.at)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            if (stock <= 0)
              Text('Bestand aufgebraucht — Nachbestellung pruefen.',
                  style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Vernichten (protokollieren)',
          icon: const Icon(Symbols.delete_forever),
          onPressed: () => _openDestructionDialog(m),
        ),
        isThreeLine: true,
        textColor: low,
      ),
    );
  }

  Future<void> _openDestructionDialog(Medication m) async {
    final employees = ref.read(employeesProvider).valueOrNull ?? const [];
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Keine Mitarbeiter hinterlegt.'),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _BtmDestructionDialog(
        medication: m,
        employees: employees,
      ),
    );
    if (ok == true) await _refresh();
  }
}

class _BtmDestructionDialog extends ConsumerStatefulWidget {
  final Medication medication;
  final List<Employee> employees;

  const _BtmDestructionDialog({
    required this.medication,
    required this.employees,
  });

  @override
  ConsumerState<_BtmDestructionDialog> createState() =>
      _BtmDestructionDialogState();
}

class _BtmDestructionDialogState
    extends ConsumerState<_BtmDestructionDialog> {
  final _menge = TextEditingController();
  final _einheit = TextEditingController(text: 'Tablette(n)');
  final _details = TextEditingController();
  String _reason = BtmDestructionReasons.expired;
  String? _destroyerId;
  String? _witnessId;
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
    final settings = ref.read(appSettingsProvider);
    final user = (settings.cloudUsername ?? '').toLowerCase();
    final me = widget.employees.cast<Employee?>().firstWhere(
          (e) => e != null && e.email.toLowerCase() == user,
          orElse: () => null,
        );
    _destroyerId = me?.id;
  }

  @override
  void dispose() {
    _menge.dispose();
    _einheit.dispose();
    _details.dispose();
    _sig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final witnessCandidates =
        widget.employees.where((e) => e.id != _destroyerId).toList();
    return AlertDialog(
      title: Text('BtM vernichten: ${widget.medication.name}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _menge,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Menge (pflicht)',
                      hintText: 'z. B. 5',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _einheit,
                    decoration: const InputDecoration(
                      labelText: 'Einheit',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Grund'),
                items: BtmDestructionReasons.all
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(BtmDestructionReasons.label(r)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _details,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'z. B. Charge abgelaufen seit 01.2026',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _destroyerId,
                decoration:
                    const InputDecoration(labelText: 'Verantwortlich'),
                items: widget.employees
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.fullName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _destroyerId = v;
                  if (_witnessId == v) _witnessId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _witnessId,
                decoration:
                    const InputDecoration(labelText: 'Zeuge (pflicht)'),
                items: witnessCandidates
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.fullName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _witnessId = v),
              ),
              const SizedBox(height: 16),
              Text('Unterschrift (optional):',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Container(
                height: 140,
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
          icon: const Icon(Symbols.delete_forever),
          label: const Text('Vernichten'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final menge = double.tryParse(_menge.text.replaceAll(',', '.').trim());
    if (menge == null || menge <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Menge > 0 angeben.'),
      ));
      return;
    }
    if (_destroyerId == null ||
        _witnessId == null ||
        _witnessId == _destroyerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verantwortlicher und Zeuge (unterschiedlich) pflicht.'),
      ));
      return;
    }
    setState(() => _submitting = true);
    final bytes = await _sig.toPngBytes();
    final sigB64 = bytes != null && _sig.isNotEmpty ? base64Encode(bytes) : null;
    final id = await BtmService().addDestruction(
      medicationId: widget.medication.id,
      clientId: widget.medication.clientId,
      menge: menge,
      mengeEinheit: _einheit.text.trim(),
      reason: _reason,
      reasonDetails:
          _details.text.trim().isEmpty ? null : _details.text.trim(),
      destroyerEmployeeId: _destroyerId!,
      witnessEmployeeId: _witnessId!,
      destroyedAt: DateTime.now(),
      signaturePngB64: sigB64,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (id != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vernichtung protokolliert.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Speichern fehlgeschlagen — pflichtangaben pruefen.'),
      ));
    }
  }
}
