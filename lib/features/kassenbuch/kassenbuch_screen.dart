import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/kassenbuch_eintrag.dart';
import '../../providers/kassenbuch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_report_service.dart';
import 'kassenbuch_close_month_dialog.dart';
import 'kassenbuch_form_dialog.dart';
import 'kassenbuch_storno_dialog.dart';

class KassenbuchScreen extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const KassenbuchScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eintraegeAsync = ref.watch(kassenbuchForClientProvider(clientId));
    final saldoAsync = ref.watch(kassenbuchSaldoProvider(clientId));
    final stornoMap = ref
            .watch(kassenbuchStornoMapProvider(clientId))
            .valueOrNull ??
        const <String, String>{};
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Kassenbuch – $clientName'),
        actions: [
          IconButton(
            tooltip: 'Monat abschliessen',
            icon: const Icon(Symbols.lock_clock),
            onPressed: () => _openCloseMonth(context),
          ),
          IconButton(
            tooltip: 'Monatsauszug (PDF)',
            icon: const Icon(Symbols.picture_as_pdf),
            onPressed: () => _exportMonth(context, ref),
          ),
          IconButton(
            tooltip: 'Eintrag erfassen',
            icon: const Icon(Symbols.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Symbols.savings,
                      size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktueller Saldo',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.colorScheme.outline)),
                        saldoAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Fehler: $e'),
                          data: (s) => Text(
                            euro.format(s),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: s < 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eintraegeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.account_balance_wallet,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('Noch keine Eintraege.'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Symbols.add),
                          label: const Text('Ersten Eintrag erfassen'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final e = list[i];
                    return _entryTile(
                        context, ref, theme, e, df, euro, stornoMap);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    KassenbuchEintrag e,
    DateFormat df,
    NumberFormat euro,
    Map<String, String> stornoMap,
  ) {
    final positive = e.betrag >= 0;
    final color = positive ? Colors.green : theme.colorScheme.error;
    final wurdeStorniert = stornoMap.containsKey(e.id);
    final istStorno = e.isStorno;
    return Card(
      color: wurdeStorniert
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
          : (e.confirmed ? theme.colorScheme.surfaceContainerLow : null),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            istStorno
                ? Symbols.undo
                : (positive ? Symbols.add : Symbols.remove),
            color: color,
          ),
        ),
        title: Text(
          e.beschreibung,
          style: wurdeStorniert
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(df.format(e.datum)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(e.kategorie.label,
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                if (e.confirmed) ...[
                  const SizedBox(width: 4),
                  const Icon(Symbols.lock, size: 14),
                ],
                if (wurdeStorniert) ...[
                  const SizedBox(width: 4),
                  _badge(theme, 'STORNIERT',
                      theme.colorScheme.errorContainer,
                      theme.colorScheme.onErrorContainer),
                ],
                if (istStorno) ...[
                  const SizedBox(width: 4),
                  _badge(theme, 'STORNO',
                      theme.colorScheme.tertiaryContainer,
                      theme.colorScheme.onTertiaryContainer),
                ],
                if (e.hasBeleg) ...[
                  const SizedBox(width: 4),
                  Icon(
                    e.belegMimeType == 'application/pdf'
                        ? Symbols.picture_as_pdf
                        : Symbols.image,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
            if (istStorno && e.stornoReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Grund: ${e.stornoReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          '${positive ? '+' : ''}${euro.format(e.betrag)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () => _openForm(context, existing: e),
        onLongPress: () => _handleLongPress(context, ref, e, wurdeStorniert),
      ),
    );
  }

  Widget _badge(ThemeData theme, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _openForm(BuildContext context,
      {KassenbuchEintrag? existing}) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => KassenbuchFormDialog(
        clientId: clientId,
        existing: existing,
      ),
    );
  }

  Future<void> _openCloseMonth(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => KassenbuchCloseMonthDialog(
        clientId: clientId,
        clientName: clientName,
      ),
    );
  }

  Future<void> _exportMonth(BuildContext context, WidgetRef ref) async {
    final month = await _pickMonth(context);
    if (month == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = ref.read(kassenbuchServiceProvider);
      final alle = await svc.loadForClient(clientId);
      final vorher = await svc.saldoBeforeMonth(clientId, month);
      final path = await PdfReportService().generateKassenbuchMonthlyStatement(
        clientId: clientId,
        clientName: clientName,
        month: month,
        saldoVorMonat: vorher,
        eintraege: alle,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Monatsauszug gespeichert: $path')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<DateTime?> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        int year = now.year;
        int month = now.month;
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            title: const Text('Monatsauszug — Monat waehlen'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: month,
                    decoration: const InputDecoration(labelText: 'Monat'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM', 'de_DE')
                                  .format(DateTime(2024, m))),
                            ))
                        .toList(),
                    onChanged: (v) => setDialog(() => month = v ?? month),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: year,
                    decoration: const InputDecoration(labelText: 'Jahr'),
                    items: List.generate(6, (i) => now.year - 2 + i)
                        .map((y) => DropdownMenuItem(
                            value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setDialog(() => year = v ?? year),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(DateTime(year, month, 1)),
                child: const Text('Export'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLongPress(
    BuildContext context,
    WidgetRef ref,
    KassenbuchEintrag e,
    bool wurdeStorniert,
  ) async {
    final canStorno = e.confirmed && !e.isStorno && !wurdeStorniert;
    final canEdit = !e.confirmed;
    if (!canStorno && !canEdit) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit) ...[
              ListTile(
                leading: const Icon(Symbols.check_circle),
                title: const Text('Freigeben (final)'),
                onTap: () => Navigator.of(ctx).pop('confirm'),
              ),
              ListTile(
                leading: const Icon(Symbols.delete),
                title: const Text('Loeschen'),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
            ],
            if (canStorno)
              ListTile(
                leading: const Icon(Symbols.undo),
                title: const Text('Stornieren (Gegenbuchung)'),
                subtitle: const Text(
                    'Erzeugt einen neuen Eintrag mit umgekehrtem Vorzeichen.'),
                onTap: () => Navigator.of(ctx).pop('storno'),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    final settings = ref.read(appSettingsProvider);
    final empId = (settings.cloudUsername ?? '').toLowerCase();
    final notifier = ref.read(kassenbuchActionProvider.notifier);
    if (action == 'confirm') {
      await notifier.confirm(e.id, e.clientId, employeeId: empId);
    } else if (action == 'delete') {
      await notifier.delete(e.id, e.clientId, employeeId: empId);
    } else if (action == 'storno') {
      if (!context.mounted) return;
      await showDialog<bool>(
        context: context,
        builder: (_) => KassenbuchStornoDialog(original: e),
      );
    }
  }
}
