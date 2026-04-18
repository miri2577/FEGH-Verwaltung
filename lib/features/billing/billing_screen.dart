import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/billing_provider.dart';
import 'empfaenger_editor_screen.dart';
import 'rechnung_erstellen_screen.dart';

/// Uebersicht aller Rechnungen mit XRechnung-Export und Storno.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rechnungen = ref.watch(rechnungenProvider);
    final empfaenger = ref.watch(empfaengerProvider);
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechnungen'),
        actions: [
          IconButton(
            tooltip: 'Empfaenger verwalten',
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _EmpfaengerListeScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Neu laden',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(rechnungenProvider.notifier).load();
              ref.read(empfaengerProvider.notifier).load();
            },
          ),
        ],
      ),
      body: rechnungen.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = list[i];
              final empf = empfaenger.valueOrNull
                  ?.where((e) => e.id == r.empfaengerId)
                  .firstOrNull;
              return Card(
                child: ListTile(
                  leading: _statusIcon(r.status, theme),
                  title: Text(
                    '${r.rechnungsnummer} · ${empf?.name ?? "(Empfaenger unbekannt)"}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${df.format(r.rechnungsdatum)} · '
                    'Brutto: ${r.gesamtBrutto.toStringAsFixed(2)} EUR · '
                    '${_statusLabel(r.status)}'
                    '${r.istStorno ? " · STORNO" : ""}',
                  ),
                  trailing: Text(
                    '${r.positionen.length} Pos.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RechnungErstellenScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Neue Rechnung'),
      ),
    );
  }

  Widget _statusIcon(RechnungStatus s, ThemeData theme) {
    switch (s) {
      case RechnungStatus.entwurf:
        return Icon(Icons.edit_note, color: theme.colorScheme.onSurfaceVariant);
      case RechnungStatus.versendet:
        return const Icon(Icons.mail, color: Colors.blue);
      case RechnungStatus.bezahlt:
        return const Icon(Icons.check_circle, color: Colors.green);
      case RechnungStatus.storniert:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  String _statusLabel(RechnungStatus s) {
    switch (s) {
      case RechnungStatus.entwurf:
        return 'Entwurf';
      case RechnungStatus.versendet:
        return 'Versendet';
      case RechnungStatus.bezahlt:
        return 'Bezahlt';
      case RechnungStatus.storniert:
        return 'Storniert';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Keine Rechnungen vorhanden',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Tippe unten rechts auf + um eine anzulegen'),
        ],
      ),
    );
  }
}

/// Empfaenger-Liste mit Anlegen / Bearbeiten / Loeschen.
class _EmpfaengerListeScreen extends ConsumerWidget {
  const _EmpfaengerListeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(empfaengerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rechnungsempfaenger')),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Keine Empfaenger angelegt'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = items[i];
              return Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                    '${e.strasse}, ${e.plz} ${e.ort}\n'
                    'Leitweg-ID: ${e.leitwegId}',
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmpfaengerEditorScreen(existing: e),
                      ),
                    );
                    ref.read(empfaengerProvider.notifier).load();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EmpfaengerEditorScreen(),
            ),
          );
          ref.read(empfaengerProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Neuer Empfaenger'),
      ),
    );
  }
}
