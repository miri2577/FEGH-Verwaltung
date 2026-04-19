import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/wohnraum.dart';
import '../../providers/client_provider.dart';
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
}
