import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/employee.dart';
import '../../models/shift.dart';
import '../../models/shift_swap_request.dart';
import '../../providers/employee_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_swap_provider.dart';
import '../../providers/team_provider.dart';

/// Zentrale Sicht auf den Tausch-Anfrage-Workflow.
///
/// Drei Tabs:
/// 1. **Meine Anfragen** — was ich selbst angefragt habe
/// 2. **Fuer mich** — offene Anfragen, die ich annehmen koennte
/// 3. **Leitungs-Freigabe** — akzeptierte Anfragen in meinen geleiteten Teams
class ShiftSwapScreen extends ConsumerStatefulWidget {
  const ShiftSwapScreen({super.key});

  @override
  ConsumerState<ShiftSwapScreen> createState() => _ShiftSwapScreenState();
}

class _ShiftSwapScreenState extends ConsumerState<ShiftSwapScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final teams = ref.watch(teamsProvider).valueOrNull ?? const [];
    final userEmail = (settings.cloudUsername ?? '').toLowerCase();
    final me = employees.cast<Employee?>().firstWhere(
          (e) => e != null && e.email.toLowerCase() == userEmail,
          orElse: () => null,
        );
    final myId = me?.id ?? '';
    final iLeadSomething =
        teams.any((t) => t.teamLeaderId == myId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tausch-Anfragen'),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            const Tab(icon: Icon(Symbols.outgoing_mail), text: 'Meine'),
            const Tab(icon: Icon(Symbols.inbox), text: 'Fuer mich'),
            Tab(
              icon: Icon(iLeadSomething
                  ? Symbols.gavel
                  : Symbols.block),
              text: 'Leitung',
            ),
          ],
        ),
      ),
      body: myId.isEmpty
          ? const Center(child: Text('Kein Mitarbeiter-Profil gefunden.'))
          : TabBarView(
              controller: _tab,
              children: [
                _myRequestsTab(myId, employees),
                _forMeTab(myId, employees),
                _leadTab(myId, employees, iLeadSomething),
              ],
            ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────

  Widget _myRequestsTab(String myId, List<Employee> employees) {
    final async = ref.watch(myShiftSwapsProvider(myId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (list) => list.isEmpty
          ? _empty(
              icon: Symbols.outgoing_mail,
              text: 'Du hast noch keine Tausch-Anfragen gestellt.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _swapCard(
                list[i],
                employees,
                actions: list[i].status.isOpen
                    ? [
                        TextButton.icon(
                          onPressed: () => _cancel(list[i].id, myId),
                          icon: const Icon(Symbols.undo, size: 18),
                          label: const Text('Zurueckziehen'),
                        ),
                      ]
                    : const [],
              ),
            ),
    );
  }

  Widget _forMeTab(String myId, List<Employee> employees) {
    final async = ref.watch(openSwapsForMeProvider(myId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (list) => list.isEmpty
          ? _empty(
              icon: Symbols.inbox,
              text: 'Aktuell keine Tausch-Anfragen fuer dich.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _swapCard(
                list[i],
                employees,
                actions: [
                  FilledButton.icon(
                    onPressed: () => _accept(list[i].id, myId),
                    icon: const Icon(Symbols.check, size: 18),
                    label: const Text('Annehmen'),
                  ),
                  TextButton.icon(
                    onPressed: () => _decline(list[i].id, myId),
                    icon: const Icon(Symbols.close, size: 18),
                    label: const Text('Ablehnen'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _leadTab(String myId, List<Employee> employees, bool iLead) {
    if (!iLead) {
      return _empty(
        icon: Symbols.gavel,
        text: 'Du leitest derzeit kein Team.',
      );
    }
    final async = ref.watch(swapsPendingLeadDecisionProvider(myId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (list) => list.isEmpty
          ? _empty(
              icon: Symbols.gavel,
              text: 'Keine offenen Entscheidungen fuer dich.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _swapCard(
                list[i],
                employees,
                actions: [
                  FilledButton.icon(
                    onPressed: () => _approve(list[i].id, myId),
                    icon: const Icon(Symbols.check_circle, size: 18),
                    label: const Text('Genehmigen'),
                  ),
                  TextButton.icon(
                    onPressed: () => _reject(list[i].id, myId),
                    icon: const Icon(Symbols.cancel, size: 18),
                    label: const Text('Ablehnen'),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Karte + Helpers ──────────────────────────────────────────

  Widget _swapCard(
    ShiftSwapRequest r,
    List<Employee> employees, {
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);
    final empById = {for (final e in employees) e.id: e};
    final shifts = ref.read(shiftsProvider).valueOrNull ?? const [];
    final shift = shifts.cast<Shift?>().firstWhere(
          (s) => s != null && s.id == r.shiftId,
          orElse: () => null,
        );

    final df = DateFormat('EEE dd.MM.yyyy HH:mm', 'de_DE');
    final requester =
        empById[r.requesterEmployeeId]?.fullName ?? r.requesterEmployeeId;
    final target = r.offeredToEmployeeId == null
        ? 'offen (Team)'
        : empById[r.offeredToEmployeeId!]?.fullName ??
            r.offeredToEmployeeId!;
    final acceptor = r.acceptingEmployeeId == null
        ? null
        : empById[r.acceptingEmployeeId!]?.fullName ??
            r.acceptingEmployeeId!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusChip(theme, r.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shift == null
                        ? 'Schicht (nicht gefunden)'
                        : '${df.format(shift.startTime)} – '
                            '${DateFormat('HH:mm').format(shift.endTime)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Von: $requester'),
            Text('Angeboten an: $target'),
            if (acceptor != null) Text('Angenommen von: $acceptor'),
            const SizedBox(height: 4),
            Text('Grund: ${r.reason}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
            if (r.leadNote != null)
              Text('Notiz Leitung: ${r.leadNote}',
                  style: theme.textTheme.bodySmall),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme, ShiftSwapStatus s) {
    final (bg, fg) = switch (s) {
      ShiftSwapStatus.pending => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer
        ),
      ShiftSwapStatus.accepted => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer
        ),
      ShiftSwapStatus.approved => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer
        ),
      ShiftSwapStatus.declined ||
      ShiftSwapStatus.rejected ||
      ShiftSwapStatus.cancelled =>
        (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        s.label,
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _empty({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Aktionen ─────────────────────────────────────────────────

  Future<void> _cancel(String id, String myId) async {
    final ok = await ref
        .read(shiftSwapActionProvider.notifier)
        .cancel(id, myId);
    _snack(ok ? 'Anfrage zurueckgezogen.' : 'Aktion fehlgeschlagen.');
  }

  Future<void> _accept(String id, String myId) async {
    final ok = await ref
        .read(shiftSwapActionProvider.notifier)
        .accept(id, myId);
    _snack(ok ? 'Angenommen — Teamleitung entscheidet.' : 'Annehmen fehlgeschlagen.');
  }

  Future<void> _decline(String id, String myId) async {
    final reason = await _askText('Grund fuer die Ablehnung (optional)');
    final ok = await ref
        .read(shiftSwapActionProvider.notifier)
        .decline(id, myId, reason: reason);
    _snack(ok ? 'Abgelehnt.' : 'Aktion fehlgeschlagen.');
  }

  Future<void> _approve(String id, String myId) async {
    final note = await _askText('Notiz (optional)');
    final ok = await ref
        .read(shiftSwapActionProvider.notifier)
        .approveByLead(id, myId, note: note);
    _snack(ok
        ? 'Genehmigt — Schicht ist umgebucht.'
        : 'Aktion fehlgeschlagen.');
  }

  Future<void> _reject(String id, String myId) async {
    final note = await _askText('Grund fuer die Ablehnung (optional)');
    final ok = await ref
        .read(shiftSwapActionProvider.notifier)
        .rejectByLead(id, myId, note: note);
    _snack(ok ? 'Abgelehnt.' : 'Aktion fehlgeschlagen.');
  }

  Future<String?> _askText(String label) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ueberspringen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    final trimmed = result?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
