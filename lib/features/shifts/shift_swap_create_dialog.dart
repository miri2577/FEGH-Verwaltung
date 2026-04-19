import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/employee.dart';
import '../../models/shift.dart';
import '../../providers/employee_provider.dart';
import '../../providers/shift_swap_provider.dart';
import '../../providers/team_provider.dart';

/// Dialog zum Erstellen einer Tausch-Anfrage fuer [shift].
class ShiftSwapCreateDialog extends ConsumerStatefulWidget {
  final Shift shift;

  const ShiftSwapCreateDialog({super.key, required this.shift});

  @override
  ConsumerState<ShiftSwapCreateDialog> createState() =>
      _ShiftSwapCreateDialogState();
}

class _ShiftSwapCreateDialogState
    extends ConsumerState<ShiftSwapCreateDialog> {
  String? _offeredTo;
  final _reason = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final teams = ref.watch(teamsProvider).valueOrNull ?? const [];

    // Kandidaten: Teammitglieder derselben Team wie die Schicht
    final teamMemberIds = <String>{};
    for (final t in teams) {
      if (widget.shift.teamId == null || t.id == widget.shift.teamId) {
        teamMemberIds.addAll(t.memberIds);
        if (t.teamLeaderId != null) teamMemberIds.add(t.teamLeaderId!);
      }
    }
    final candidates = employees
        .where((e) =>
            e.id != widget.shift.employeeId &&
            (teamMemberIds.isEmpty || teamMemberIds.contains(e.id)))
        .toList();

    final df = DateFormat('EEE dd.MM.yyyy HH:mm', 'de_DE');

    return AlertDialog(
      title: const Text('Tausch anbieten'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  const Icon(Symbols.swap_horiz, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${df.format(widget.shift.startTime)} – '
                      '${DateFormat('HH:mm').format(widget.shift.endTime)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _offeredTo,
              decoration: const InputDecoration(
                labelText: 'Empfaenger (optional)',
              ),
              hint: const Text('Offen fuer das Team'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('— offen fuer alle im Team —')),
                ...candidates.map((Employee e) => DropdownMenuItem<String?>(
                      value: e.id,
                      child: Text(e.fullName),
                    )),
              ],
              onChanged: (v) => setState(() => _offeredTo = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Grund (pflicht)',
                hintText: 'z. B. Arzttermin, privater Termin',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Annahme durch Kollegen macht die Anfrage nicht sofort '
              'wirksam — die Teamleitung muss final genehmigen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Symbols.send),
          label: const Text('Anfrage stellen'),
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
    setState(() => _submitting = true);
    final id = await ref.read(shiftSwapActionProvider.notifier).createRequest(
          shift: widget.shift,
          requesterEmployeeId: widget.shift.employeeId,
          offeredToEmployeeId: _offeredTo,
          reason: reason,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (id != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tausch-Anfrage erstellt.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Anfrage fehlgeschlagen (vermutlich schon eine offene Anfrage).')),
      );
    }
  }
}
