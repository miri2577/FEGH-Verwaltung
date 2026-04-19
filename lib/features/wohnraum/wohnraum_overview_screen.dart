import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../models/kassenbuch_eintrag.dart';
import '../../models/wohnraum.dart';
import '../../providers/client_provider.dart';
import '../../providers/kassenbuch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wohnraum_provider.dart';
import 'wohnraum_form_dialog.dart';

class WohnraumOverviewScreen extends ConsumerStatefulWidget {
  const WohnraumOverviewScreen({super.key});

  @override
  ConsumerState<WohnraumOverviewScreen> createState() =>
      _WohnraumOverviewScreenState();
}

class _WohnraumOverviewScreenState
    extends ConsumerState<WohnraumOverviewScreen> {
  WohnraumStatus? _statusFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wAsync = ref.watch(allWohnraeumeProvider);
    final clients = ref.watch(clientProvider);
    final clientMap = {for (final c in clients) c.id: c};
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wohnraum'),
        actions: [
          IconButton(
            tooltip: 'Hinzufuegen',
            icon: const Icon(Symbols.add),
            onPressed: _openAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Symbols.search),
                      labelText: 'Suche (Bezeichnung, Adresse)',
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<WohnraumStatus?>(
                  value: _statusFilter,
                  hint: const Text('Alle Status'),
                  onChanged: (v) => setState(() => _statusFilter = v),
                  items: [
                    const DropdownMenuItem<WohnraumStatus?>(
                        value: null, child: Text('Alle Status')),
                    ...WohnraumStatus.values.map(
                      (s) => DropdownMenuItem(
                          value: s, child: Text(s.label)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: wAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (list) {
                final filtered = list.where((w) {
                  if (_statusFilter != null && w.status != _statusFilter) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    final txt = [w.bezeichnung, w.adresse ?? '']
                        .join(' ')
                        .toLowerCase();
                    if (!txt.contains(q)) return false;
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => a.bezeichnung.compareTo(b.bezeichnung));

                if (filtered.isEmpty) {
                  return const Center(child: Text('Keine Eintraege.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final w = filtered[i];
                    final client = w.clientId == null
                        ? null
                        : clientMap[w.clientId];
                    return Card(
                      child: ListTile(
                        leading: _statusIcon(theme, w.status),
                        title: Text(w.bezeichnung),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warmmiete ${euro.format(w.warmmiete)}'
                              '${w.adresse != null ? "  |  ${w.adresse}" : ""}',
                            ),
                            if (client != null)
                              Text('Bewohner: ${client.fullName}',
                                  style: TextStyle(
                                      color: theme.colorScheme.primary)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                                label: Text(w.status.label,
                                    style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              onSelected: (v) => _handleMenu(v, w),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Bearbeiten')),
                                if (w.status == WohnraumStatus.free)
                                  const PopupMenuItem(
                                      value: 'assign',
                                      child: Text('Klient zuweisen')),
                                if (w.status == WohnraumStatus.occupied)
                                  const PopupMenuItem(
                                      value: 'release',
                                      child: Text('Freigeben')),
                                if (w.status == WohnraumStatus.occupied &&
                                    w.warmmiete > 0)
                                  const PopupMenuItem(
                                      value: 'bookRent',
                                      child: Text('Miete buchen…')),
                                if (w.status == WohnraumStatus.occupied)
                                  const PopupMenuItem(
                                      value: 'bookNk',
                                      child:
                                          Text('Nebenkostenabrechnung…')),
                                if (w.status != WohnraumStatus.inactive)
                                  const PopupMenuItem(
                                      value: 'deactivate',
                                      child: Text('Deaktivieren')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(ThemeData theme, WohnraumStatus s) {
    switch (s) {
      case WohnraumStatus.free:
        return Icon(Symbols.check_circle, color: Colors.green);
      case WohnraumStatus.occupied:
        return Icon(Symbols.person, color: theme.colorScheme.primary);
      case WohnraumStatus.reserved:
        return const Icon(Symbols.bookmark, color: Colors.blue);
      case WohnraumStatus.inactive:
        return Icon(Symbols.block, color: theme.colorScheme.outline);
    }
  }

  Future<void> _openAddDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const WohnraumFormDialog(),
    );
  }

  Future<void> _handleMenu(String action, Wohnraum w) async {
    final notifier = ref.read(wohnraumActionProvider.notifier);
    switch (action) {
      case 'edit':
        await showDialog<bool>(
          context: context,
          builder: (_) => WohnraumFormDialog(existing: w),
        );
        break;
      case 'assign':
        await _showAssignDialog(w);
        break;
      case 'release':
        final ok = await _confirm(
          'Wohnraum freigeben?',
          'Bewohner wird entfernt, Wohnraum steht auf "frei".',
        );
        if (ok == true) await notifier.releaseClient(w.id);
        break;
      case 'deactivate':
        final ok = await _confirm(
          'Wohnraum deaktivieren?',
          'Der Eintrag wird aus der aktiven Liste ausgeblendet.',
        );
        if (ok == true) await notifier.deactivate(w.id);
        break;
      case 'bookRent':
        await _bookRent(w);
        break;
      case 'bookNk':
        await _bookNebenkosten(w);
        break;
    }
  }

  Future<void> _showAssignDialog(Wohnraum w) async {
    final clients = ref.read(clientProvider);
    String? selected;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Klient zuweisen'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Klient'),
              items: clients
                  .map((c) => DropdownMenuItem<String>(
                      value: c.id, child: Text(c.fullName)))
                  .toList(),
              onChanged: (v) => setDialog(() => selected = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(ctx).pop(selected),
              child: const Text('Zuweisen'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await ref
          .read(wohnraumActionProvider.notifier)
          .assignClient(w.id, result);
    }
  }

  Future<bool?> _confirm(String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookRent(Wohnraum w) async {
    final clientId = w.clientId;
    if (clientId == null || clientId.isEmpty) return;
    final month = await _pickMonth();
    if (month == null) return;
    if (!mounted) return;

    // Schon gebucht?
    final kbSvc = ref.read(kassenbuchServiceProvider);
    final existing = await kbSvc.loadForClientInMonth(clientId, month);
    final tag = _rentTag(w.id, month);
    final alreadyBooked =
        existing.any((e) => (e.belegnummer ?? '').contains(tag));
    if (!mounted) return;
    if (alreadyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Miete fuer ${DateFormat('MMMM yyyy', 'de_DE').format(month)} ist '
            'bereits gebucht.'),
      ));
      return;
    }

    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final ok = await _confirm(
      'Miete buchen',
      'Warmmiete ${euro.format(w.warmmiete)} fuer '
          '${DateFormat('MMMM yyyy', 'de_DE').format(month)} als Abbuchung '
          'im Kassenbuch erfassen?',
    );
    if (ok != true) return;

    final settings = ref.read(appSettingsProvider);
    final empId = (settings.cloudUsername ?? '').toLowerCase();
    final entry = KassenbuchEintrag(
      id: const Uuid().v4(),
      clientId: clientId,
      datum: DateTime(month.year, month.month, 1),
      betrag: -w.warmmiete,
      kategorie: KassenbuchKategorie.haushaltsgeld,
      beschreibung: 'Miete ${DateFormat('MM/yyyy').format(month)}: '
          '${w.bezeichnung}',
      belegnummer: tag,
      erfasstVonEmployeeId: empId.isEmpty ? null : empId,
      confirmed: true,
      createdAt: DateTime.now(),
    );
    final success = await ref.read(kassenbuchActionProvider.notifier).add(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Miete ${euro.format(w.warmmiete)} gebucht.'
          : 'Buchung fehlgeschlagen (Monat evtl. abgeschlossen).'),
    ));
  }

  Future<void> _bookNebenkosten(Wohnraum w) async {
    final clientId = w.clientId;
    if (clientId == null || clientId.isEmpty) return;
    final result = await showDialog<({double betrag, String zweck})>(
      context: context,
      builder: (ctx) => _NebenkostenDialog(wohnraumLabel: w.bezeichnung),
    );
    if (result == null) return;
    if (!mounted) return;

    final settings = ref.read(appSettingsProvider);
    final empId = (settings.cloudUsername ?? '').toLowerCase();
    final entry = KassenbuchEintrag(
      id: const Uuid().v4(),
      clientId: clientId,
      datum: DateTime.now(),
      betrag: -result.betrag.abs(),
      kategorie: KassenbuchKategorie.haushaltsgeld,
      beschreibung: 'Nebenkostenabrechnung: ${result.zweck}',
      belegnummer: 'NK-${w.id.substring(0, 6)}-'
          '${DateTime.now().millisecondsSinceEpoch}',
      erfasstVonEmployeeId: empId.isEmpty ? null : empId,
      confirmed: false,
      createdAt: DateTime.now(),
    );
    final ok = await ref.read(kassenbuchActionProvider.notifier).add(entry);
    if (!mounted) return;
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Nebenkosten ${euro.format(result.betrag)} gebucht.'
          : 'Buchung fehlgeschlagen.'),
    ));
  }

  Future<DateTime?> _pickMonth() async {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Miet-Monat waehlen'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: month,
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
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'Jahr'),
                  items: List.generate(6, (i) => now.year - 2 + i)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
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
              onPressed: () => Navigator.of(ctx).pop(DateTime(year, month, 1)),
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }

  String _rentTag(String wohnraumId, DateTime month) =>
      'RENT-${wohnraumId.substring(0, 6)}-'
      '${month.year}${month.month.toString().padLeft(2, '0')}';
}

class _NebenkostenDialog extends StatefulWidget {
  final String wohnraumLabel;
  const _NebenkostenDialog({required this.wohnraumLabel});

  @override
  State<_NebenkostenDialog> createState() => _NebenkostenDialogState();
}

class _NebenkostenDialogState extends State<_NebenkostenDialog> {
  final _betrag = TextEditingController();
  final _zweck = TextEditingController();

  @override
  void dispose() {
    _betrag.dispose();
    _zweck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nebenkostenabrechnung'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wohnraum: ${widget.wohnraumLabel}',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _betrag,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Betrag (EUR)',
                hintText: 'z. B. 245,50',
                prefixIcon: Icon(Symbols.euro),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zweck,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Zweck',
                hintText: 'z. B. Nebenkostennachzahlung 2025 (Heizung)',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buchung erfolgt als offener Kassenbuch-Eintrag und kann '
              'noch bearbeitet/freigegeben werden.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final v =
                double.tryParse(_betrag.text.replaceAll(',', '.').trim());
            final z = _zweck.text.trim();
            if (v == null || v <= 0 || z.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Betrag > 0 und Zweck pflicht.'),
              ));
              return;
            }
            Navigator.of(context).pop((betrag: v, zweck: z));
          },
          child: const Text('Buchen'),
        ),
      ],
    );
  }
}
