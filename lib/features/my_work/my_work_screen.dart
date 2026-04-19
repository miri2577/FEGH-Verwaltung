import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/medication_administration.dart';
import '../../models/shift.dart';
import '../../providers/client_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shift_provider.dart';
import '../kassenbuch/kassenbuch_client_picker_screen.dart';

/// Startseite fuer `teamMember` und `teamLead`: eigene Schichten,
/// offene Aufgaben (Medikation, Kassenbuch — folgen in D3/D4), letzte
/// Benachrichtigungen. Kompakte, scroll-arme Uebersicht.
class MyWorkScreen extends ConsumerWidget {
  const MyWorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shiftsAsync = ref.watch(shiftsProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final settings = ref.watch(appSettingsProvider);

    final myUser = (settings.cloudUsername ?? '').toLowerCase();
    final employees = employeesAsync.valueOrNull ?? const [];

    String? myEmployeeId;
    for (final e in employees) {
      if (e.email.toLowerCase() == myUser) {
        myEmployeeId = e.id;
        break;
      }
    }

    final shifts = shiftsAsync.valueOrNull ?? const <Shift>[];
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final tomorrowKey = todayKey.add(const Duration(days: 1));

    final mine = myEmployeeId == null
        ? const <Shift>[]
        : shifts
            .where((s) =>
                s.employeeId == myEmployeeId &&
                s.status != ShiftStatus.cancelled)
            .toList();
    final todays = mine
        .where((s) => _sameDay(s.startTime, todayKey))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final tomorrows = mine
        .where((s) => _sameDay(s.startTime, tomorrowKey))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.work, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Meine Arbeit', style: theme.textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 24),
            if (myEmployeeId == null)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Symbols.info,
                          color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kein Mitarbeiter-Profil fuer "$myUser" gefunden. '
                          'Wende dich an die Administration.',
                          style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _shiftsCard(theme, 'Heute', todays),
            const SizedBox(height: 16),
            _shiftsCard(theme, 'Morgen', tomorrows),
            const SizedBox(height: 16),
            _openMedsCard(theme, ref),
            const SizedBox(height: 16),
            _kassenbuchHintCard(theme, context),
            const SizedBox(height: 16),
            _notificationsCard(theme, ref),
          ],
        ),
      ),
    );
  }

  Widget _shiftsCard(ThemeData theme, String title, List<Shift> shifts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(width: 12),
                Text(
                  '(${shifts.length})',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shifts.isEmpty)
              Text(
                'Keine Schicht.',
                style: TextStyle(color: theme.colorScheme.outline),
              )
            else
              ...shifts.map((s) => _shiftTile(theme, s)),
          ],
        ),
      ),
    );
  }

  Widget _shiftTile(ThemeData theme, Shift s) {
    final time =
        '${DateFormat('HH:mm').format(s.startTime)} - ${DateFormat('HH:mm').format(s.endTime)}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Symbols.play_arrow),
      title: Text(time),
      subtitle: Text(
        '${s.scheduledHours.toStringAsFixed(1)} h'
        '${s.location != null ? '  |  ${s.location}' : ''}',
      ),
      trailing: Text(s.type.name),
    );
  }

  Widget _openMedsCard(ThemeData theme, WidgetRef ref) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final slotsAsync = ref.watch(todaysSlotsProvider(todayKey));
    final clients = ref.watch(clientProvider);
    final clientMap = {for (final c in clients) c.id: c};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.medication, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Offene Medikationsgaben heute',
                    style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            slotsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
              data: (slots) {
                final open = slots
                    .where((s) => s.status == AdministrationStatus.pending)
                    .toList();
                if (open.isEmpty) {
                  return Text('Keine offenen Gaben. 👍',
                      style: TextStyle(color: theme.colorScheme.outline));
                }
                final show = open.take(5).toList();
                return Column(
                  children: [
                    ...show.map((s) {
                      final name = clientMap[s.clientId]?.fullName ?? s.clientId;
                      final time =
                          DateFormat('HH:mm').format(s.scheduledAt);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Symbols.pill),
                        title: Text('$time  |  $name'),
                        subtitle: Text(
                            '${s.medication.name}  |  ${s.medication.dosage}'),
                      );
                    }),
                    if (open.length > show.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${open.length - show.length} weitere offen',
                          style:
                              TextStyle(color: theme.colorScheme.outline),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _kassenbuchHintCard(ThemeData theme, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Symbols.savings, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kassenbuch',
                      style: theme.textTheme.titleMedium),
                  Text(
                    'Taschengeld, Haushaltsgeld, Quittungen pro Klient.',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KassenbuchClientPickerScreen(),
                  ),
                );
              },
              icon: const Icon(Symbols.arrow_forward),
              label: const Text('Oeffnen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(text,
                      style: TextStyle(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsCard(ThemeData theme, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);
    final recent = notifs.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.notifications, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Letzte Benachrichtigungen',
                    style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Text(
                'Keine neuen Benachrichtigungen.',
                style: TextStyle(color: theme.colorScheme.outline),
              )
            else
              ...recent.map((n) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Symbols.circle_notifications),
                    title: Text(n.title),
                    subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  )),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
