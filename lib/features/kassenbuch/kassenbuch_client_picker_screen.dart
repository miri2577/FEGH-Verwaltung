import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../providers/client_provider.dart';
import '../../providers/kassenbuch_provider.dart';
import 'kassenbuch_screen.dart';

/// Mitarbeiter-Sicht: Liste aller Klienten + Saldo. Tap oeffnet das
/// individuelle Kassenbuch.
class KassenbuchClientPickerScreen extends ConsumerWidget {
  const KassenbuchClientPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientProvider);
    final theme = Theme.of(context);
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final sorted = [...clients]..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Scaffold(
      appBar: AppBar(title: const Text('Kassenbuch')),
      body: sorted.isEmpty
          ? const Center(child: Text('Keine Klienten vorhanden.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final c = sorted[i];
                final saldoAsync =
                    ref.watch(kassenbuchSaldoProvider(c.id));
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Symbols.savings,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(c.fullName),
                    subtitle: saldoAsync.when(
                      loading: () => const Text('…'),
                      error: (e, _) => const Text('Fehler'),
                      data: (s) => Text(
                        'Saldo: ${euro.format(s)}',
                        style: TextStyle(
                          color: s < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KassenbuchScreen(
                            clientId: c.id,
                            clientName: c.fullName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
