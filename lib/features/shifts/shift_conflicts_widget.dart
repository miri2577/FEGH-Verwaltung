import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/shift_conflict_checker.dart';

/// Zeigt eine Liste von [ShiftConflict]s in einer kompakten Karte.
/// Leere Liste rendert nichts.
class ShiftConflictsWidget extends StatelessWidget {
  final List<ShiftConflict> conflicts;

  const ShiftConflictsWidget({super.key, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final hasBlocking =
        conflicts.any((c) => c.severity == ShiftConflictSeverity.blocking);

    final color = hasBlocking
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final onColor = hasBlocking
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;
    final icon = hasBlocking ? Symbols.block : Symbols.warning;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: onColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  hasBlocking
                      ? 'Planung nicht zulaessig'
                      : 'Hinweise zur Planung',
                  style: theme.textTheme.titleSmall?.copyWith(color: onColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...conflicts.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_iconFor(c.kind), color: onColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.message,
                          style: TextStyle(color: onColor, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ShiftConflictKind kind) {
    switch (kind) {
      case ShiftConflictKind.employeeOverlap:
        return Symbols.sync_problem;
      case ShiftConflictKind.restPeriodTooShort:
        return Symbols.bedtime_off;
      case ShiftConflictKind.weeklyHoursExceeded:
        return Symbols.calendar_month;
      case ShiftConflictKind.dailyHoursExceeded:
        return Symbols.schedule;
    }
  }

  /// Hilfsfunktion fuer Submit-Buttons: verhindert Speichern, wenn
  /// mind. ein blocking-Konflikt vorliegt.
  static bool hasBlocking(List<ShiftConflict> conflicts) {
    return conflicts.any((c) => c.severity == ShiftConflictSeverity.blocking);
  }
}
