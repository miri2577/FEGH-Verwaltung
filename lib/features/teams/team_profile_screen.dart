import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/team.dart';
import '../../models/employee.dart';
import '../../models/shift.dart';
import '../../models/vacation_request.dart';
import '../../models/timesheet.dart';
import '../../providers/team_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/vacation_provider.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/policy_provider.dart';
import '../employees/employee_profile_screen.dart';
import 'widgets/team_form_dialog.dart';

class TeamProfileScreen extends ConsumerStatefulWidget {
  final String teamId;

  const TeamProfileScreen({
    super.key,
    required this.teamId,
  });

  @override
  ConsumerState<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends ConsumerState<TeamProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(teamByIdProvider(widget.teamId));
    final employeesAsync = ref.watch(employeesProvider);

    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team nicht gefunden')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.group_off, size: 64),
              SizedBox(height: 16),
              Text('Team wurde nicht gefunden.'),
            ],
          ),
        ),
      );
    }

    final members = employeesAsync.valueOrNull
            ?.where((e) => team.memberIds.contains(e.id))
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          if (ref.read(policyProvider).canManageTeams())
            IconButton(
              onPressed: () => _showEditDialog(team),
              icon: const Icon(Symbols.edit),
              tooltip: 'Bearbeiten',
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Symbols.download),
                    SizedBox(width: 8),
                    Text('Team exportieren'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Symbols.print),
                    SizedBox(width: 8),
                    Text('Team drucken'),
                  ],
                ),
              ),
              if (team.status == TeamStatus.active)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Symbols.pause_circle, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Pausieren'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Symbols.play_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Aktivieren'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) => _handleMenuAction(value, team, members),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Symbols.info), text: 'Übersicht'),
            Tab(icon: Icon(Symbols.group), text: 'Mitglieder'),
            Tab(icon: Icon(Symbols.analytics), text: 'Statistiken'),
            Tab(icon: Icon(Symbols.work), text: 'Schichten'),
            Tab(icon: Icon(Symbols.calendar_month), text: 'Kalender'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(team, members),
          _buildMembersTab(team, members),
          _buildStatsTab(team, members),
          _buildShiftsTab(team, members),
          _buildCalendarTab(team, members),
        ],
      ),
    );
  }

  // ──────────────────────────── Tab 1: Übersicht ────────────────────────────

  Widget _buildOverviewTab(Team team, List<Employee> members) {
    final teamLeader = team.teamLeaderId != null
        ? members.where((e) => e.id == team.teamLeaderId).firstOrNull
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTeamInfoCard(team, teamLeader),
          const SizedBox(height: 24),
          _buildTeamDetailsCard(team),
          const SizedBox(height: 24),
          _buildQuickStatsRow(team, members),
        ],
      ),
    );
  }

  Widget _buildTeamInfoCard(Team team, Employee? teamLeader) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Symbols.corporate_fare,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusBadge(team.status),
                      const SizedBox(width: 12),
                      if (team.department != null) ...[
                        Icon(Symbols.apartment, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(team.department!, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 12),
                      ],
                      Icon(Symbols.group, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${team.memberCount} Mitglieder', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            if (teamLeader != null)
              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      '${teamLeader.firstName[0]}${teamLeader.lastName[0]}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teamleiter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    teamLeader.fullName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TeamStatus status) {
    final (label, color) = switch (status) {
      TeamStatus.active => ('Aktiv', Colors.green),
      TeamStatus.inactive => ('Inaktiv', Colors.grey),
      TeamStatus.onHold => ('Pausiert', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildTeamDetailsCard(Team team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.info, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Team-Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Team-ID', team.id),
            _buildInfoRow('Abteilung', team.department ?? 'Nicht zugeordnet'),
            _buildInfoRow('Standort', team.location ?? 'Nicht angegeben'),
            _buildInfoRow('Budget', team.budget != null
                ? '${team.budget!.toStringAsFixed(2)} \u20ac'
                : 'Nicht festgelegt'),
            _buildInfoRow('Erstellt am',
                '${team.createdAt.day}.${team.createdAt.month}.${team.createdAt.year}'),
            _buildInfoRow('Aktualisiert am',
                '${team.updatedAt.day}.${team.updatedAt.month}.${team.updatedAt.year}'),
            if (team.notes != null && team.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('Notizen', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(team.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(Team team, List<Employee> members) {
    final activeMembers = members.where((e) => e.status == EmployeeStatus.active).length;
    final totalHoursPerWeek = members
        .where((e) => e.status == EmployeeStatus.active)
        .fold(0.0, (sum, e) => sum + e.contractualHours);

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Aktive Mitglieder',
            '$activeMembers/${team.memberCount}',
            'Mitarbeiter',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            'Wochenkapazität',
            '${totalHoursPerWeek.toStringAsFixed(0)}h',
            'Soll-Stunden/Woche',
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            'Durchschnittslohn',
            members.isEmpty
                ? '0.00 \u20ac'
                : '${(members.fold(0.0, (sum, e) => sum + e.hourlyRate) / members.length).toStringAsFixed(2)} \u20ac',
            'pro Stunde',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            'Budget',
            team.budget != null ? '${team.budget!.toStringAsFixed(0)} \u20ac' : 'N/A',
            'Gesamt',
            Colors.purple,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────── Tab 2: Mitglieder ────────────────────────────

  Widget _buildMembersTab(Team team, List<Employee> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.group_off, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Keine Mitglieder in diesem Team',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (ref.read(policyProvider).canManageTeams())
              FilledButton.icon(
                onPressed: () => _showEditDialog(team),
                icon: const Icon(Symbols.person_add),
                label: const Text('Mitglieder hinzufügen'),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Team-Mitglieder (${members.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (ref.read(policyProvider).canManageTeams())
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(team),
                  icon: const Icon(Symbols.person_add, size: 18),
                  label: const Text('Verwalten'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = members[index];
                final isLeader = member.id == team.teamLeaderId;
                return _buildMemberCard(member, isLeader, team);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Employee member, bool isLeader, Team team) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLeader
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            '${member.firstName[0]}${member.lastName[0]}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLeader
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isLeader) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: const Text(
                  'Teamleiter',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(member.position),
            const SizedBox(width: 16),
            Icon(
              member.status == EmployeeStatus.active ? Symbols.circle : Symbols.cancel,
              size: 12,
              color: member.status == EmployeeStatus.active ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              member.statusLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Text(
              '${member.contractualHours}h/Woche',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Symbols.open_in_new, size: 20),
              tooltip: 'Profil öffnen',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmployeeProfileScreen(employeeId: member.id),
                  ),
                );
              },
            ),
            if (ref.read(policyProvider).canManageTeams() && !isLeader)
              IconButton(
                icon: Icon(Symbols.person_remove, size: 20, color: Colors.red.shade300),
                tooltip: 'Aus Team entfernen',
                onPressed: () => _confirmRemoveMember(team, member),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EmployeeProfileScreen(employeeId: member.id),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────── Tab 3: Statistiken ────────────────────────────

  Widget _buildStatsTab(Team team, List<Employee> members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTeamPerformanceCard(team, members),
          const SizedBox(height: 24),
          _buildVacationOverviewCard(team, members),
          const SizedBox(height: 24),
          _buildMemberComparisonCard(members),
        ],
      ),
    );
  }

  Widget _buildTeamPerformanceCard(Team team, List<Employee> members) {
    double totalWorkedHours = 0;
    double totalOvertimeHours = 0;
    int totalCompletedShifts = 0;
    int totalScheduledShifts = 0;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final member in members) {
      final timesheets = ref.watch(timesheetsByEmployeeProvider(member.id)).valueOrNull ?? [];
      final shifts = ref.watch(shiftsByEmployeeProvider(member.id)).valueOrNull ?? [];

      final monthTimesheets = timesheets.where((ts) =>
          ts.startDate.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
      totalWorkedHours += monthTimesheets.fold(0.0, (sum, ts) => sum + ts.calculatedTotalHours);
      totalOvertimeHours += monthTimesheets.fold(0.0, (sum, ts) => sum + ts.calculatedOvertimeHours);

      final monthShifts = shifts.where((s) =>
          s.startTime.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          s.startTime.isBefore(now)).toList();
      totalScheduledShifts += monthShifts.length;
      totalCompletedShifts += monthShifts
          .where((s) => s.status == ShiftStatus.completed || s.status == ShiftStatus.inProgress)
          .length;
    }

    final attendance = totalScheduledShifts == 0
        ? 100.0
        : (totalCompletedShifts / totalScheduledShifts * 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.trending_up, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Team-Leistung (aktueller Monat)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Gesamtstunden',
                    '${totalWorkedHours.toStringAsFixed(1)}h',
                    'diesen Monat',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Überstunden',
                    '${totalOvertimeHours.toStringAsFixed(1)}h',
                    'diesen Monat',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Anwesenheit',
                    '${attendance.toStringAsFixed(0)}%',
                    '$totalCompletedShifts/$totalScheduledShifts Schichten',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Stunden/Mitarbeiter',
                    members.isEmpty
                        ? '0h'
                        : '${(totalWorkedHours / members.length).toStringAsFixed(1)}h',
                    'Durchschnitt',
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacationOverviewCard(Team team, List<Employee> members) {
    int totalVacationDays = 0;
    int pendingRequests = 0;
    int membersOnVacation = 0;

    for (final member in members) {
      final vacations = ref.watch(vacationRequestsByEmployeeProvider(member.id)).valueOrNull ?? [];
      final now = DateTime.now();

      for (final v in vacations) {
        if (v.status == VacationRequestStatus.approved) {
          totalVacationDays += v.workingDays;
          if (v.startDate.isBefore(now) && v.endDate.isAfter(now)) {
            membersOnVacation++;
          }
        }
        if (v.status == VacationRequestStatus.pending) {
          pendingRequests++;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.beach_access, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Urlaubsübersicht',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Aktuell im Urlaub',
                    '$membersOnVacation',
                    'Mitarbeiter',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Offene Anträge',
                    '$pendingRequests',
                    'ausstehend',
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Genehmigte Tage',
                    '$totalVacationDays',
                    'gesamt genehmigt',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberComparisonCard(List<Employee> members) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.leaderboard, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Mitarbeiter-Vergleich (aktueller Monat)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...members.map((member) {
              final timesheets = ref.watch(timesheetsByEmployeeProvider(member.id)).valueOrNull ?? [];
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);
              final monthTimesheets = timesheets.where((ts) =>
                  ts.startDate.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
              final workedHours = monthTimesheets.fold(0.0, (sum, ts) => sum + ts.calculatedTotalHours);
              final targetHours = member.contractualHours * 4.33; // ~monthly
              final progress = targetHours > 0 ? (workedHours / targetHours).clamp(0.0, 1.5) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress.toDouble(),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: progress > 1.0 ? Colors.orange : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${workedHours.toStringAsFixed(1)}h / ${targetHours.toStringAsFixed(0)}h',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── Tab 4: Schichten ────────────────────────────

  Widget _buildShiftsTab(Team team, List<Employee> members) {
    final shiftsAsync = ref.watch(shiftsByTeamProvider(team.id));

    // Also collect shifts by member IDs as fallback
    final List<Shift> allMemberShifts = [];
    for (final member in members) {
      final memberShifts = ref.watch(shiftsByEmployeeProvider(member.id)).valueOrNull ?? [];
      allMemberShifts.addAll(memberShifts);
    }

    final teamShifts = shiftsAsync.valueOrNull ?? [];
    final shifts = teamShifts.isNotEmpty ? teamShifts : allMemberShifts;

    // Sort by date descending
    shifts.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Only show current month and future
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final relevantShifts = shifts.where((s) =>
        s.startTime.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Team-Schichten (${relevantShifts.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _exportTeamShiftsPdf(team, members, relevantShifts),
                icon: const Icon(Symbols.picture_as_pdf, size: 18),
                label: const Text('PDF Export'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: relevantShifts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.event_busy, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('Keine Schichten in diesem Monat',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: relevantShifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final shift = relevantShifts[index];
                      final employee = members.where((e) => e.id == shift.employeeId).firstOrNull;
                      return _buildShiftCard(shift, employee);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Shift shift, Employee? employee) {
    final statusColor = switch (shift.status) {
      ShiftStatus.scheduled => Colors.blue,
      ShiftStatus.inProgress => Colors.orange,
      ShiftStatus.completed => Colors.green,
      ShiftStatus.cancelled => Colors.red,
      ShiftStatus.noShow => Colors.deepOrange,
    };

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getShiftTypeIcon(shift.type), color: statusColor),
        ),
        title: Text(
          employee?.fullName ?? 'Unbekannter Mitarbeiter',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${shift.startTime.day}.${shift.startTime.month}.${shift.startTime.year}  '
          '${shift.startTime.hour}:${shift.startTime.minute.toString().padLeft(2, '0')} - '
          '${shift.endTime.hour}:${shift.endTime.minute.toString().padLeft(2, '0')}',
        ),
        trailing: _buildStatusBadge2(shift.status),
      ),
    );
  }

  Widget _buildStatusBadge2(ShiftStatus status) {
    final (label, color) = switch (status) {
      ShiftStatus.scheduled => ('Geplant', Colors.blue),
      ShiftStatus.inProgress => ('Aktiv', Colors.orange),
      ShiftStatus.completed => ('Erledigt', Colors.green),
      ShiftStatus.cancelled => ('Abgesagt', Colors.red),
      ShiftStatus.noShow => ('Nicht erschienen', Colors.deepOrange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  // ──────────────────────────── Tab 5: Kalender ────────────────────────────

  Widget _buildCalendarTab(Team team, List<Employee> members) {
    final List<Shift> allShifts = [];
    final List<VacationRequest> allVacations = [];
    final List<Timesheet> allTimesheets = [];

    for (final member in members) {
      allShifts.addAll(ref.watch(shiftsByEmployeeProvider(member.id)).valueOrNull ?? []);
      allVacations.addAll(ref.watch(vacationRequestsByEmployeeProvider(member.id)).valueOrNull ?? []);
      allTimesheets.addAll(ref.watch(timesheetsByEmployeeProvider(member.id)).valueOrNull ?? []);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Symbols.calendar_month, size: 24),
              const SizedBox(width: 12),
              Text(
                'Team-Kalender - ${team.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              _buildCalendarLegend(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SfCalendar(
              view: CalendarView.month,
              dataSource: _TeamCalendarDataSource(
                shifts: allShifts,
                vacations: allVacations,
                timesheets: allTimesheets,
                members: members,
              ),
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                showAgenda: true,
                agendaViewHeight: 250,
                numberOfWeeksInView: 6,
              ),
              firstDayOfWeek: 1,
              showNavigationArrow: true,
              showDatePickerButton: true,
              allowedViews: const [
                CalendarView.day,
                CalendarView.week,
                CalendarView.month,
              ],
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 6,
                endHour: 22,
                timeFormat: 'HH:mm',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendItem('Schicht', Colors.blue),
        const SizedBox(width: 12),
        _legendItem('Überstunden', Colors.red),
        const SizedBox(width: 12),
        _legendItem('Urlaub', Colors.green),
        const SizedBox(width: 12),
        _legendItem('Krank', Colors.orange),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // ──────────────────────────── Helpers ────────────────────────────

  Widget _buildMetricTile(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  IconData _getShiftTypeIcon(ShiftType type) {
    return switch (type) {
      ShiftType.regular => Symbols.work,
      ShiftType.overtime => Symbols.more_time,
      ShiftType.holiday => Symbols.celebration,
      ShiftType.night => Symbols.dark_mode,
      ShiftType.weekend => Symbols.weekend,
    };
  }

  // ──────────────────────────── Actions ────────────────────────────

  void _showEditDialog(Team team) {
    showDialog(
      context: context,
      builder: (context) => TeamFormDialog(
        team: team,
        onSave: (updatedTeam) async {
          await ref.read(teamsProvider.notifier).updateTeam(updatedTeam);
        },
      ),
    );
  }

  void _handleMenuAction(String action, Team team, List<Employee> members) {
    switch (action) {
      case 'export':
        _exportTeamPdf(team, members);
        break;
      case 'print':
        _printTeamPdf(team, members);
        break;
      case 'activate':
        _updateTeamStatus(team, TeamStatus.active);
        break;
      case 'deactivate':
        _updateTeamStatus(team, TeamStatus.onHold);
        break;
    }
  }

  void _updateTeamStatus(Team team, TeamStatus status) {
    final updated = team.copyWith(status: status);
    ref.read(teamsProvider.notifier).updateTeam(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == TeamStatus.active
            ? 'Team wurde aktiviert'
            : 'Team wurde pausiert'),
      ),
    );
  }

  void _confirmRemoveMember(Team team, Employee member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mitglied entfernen'),
        content: Text('Möchten Sie ${member.fullName} aus dem Team "${team.name}" entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teamsProvider.notifier).removeMemberFromTeam(team.id, member.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.fullName} wurde aus dem Team entfernt')),
              );
            },
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── PDF ────────────────────────────

  pw.Document _buildTeamPdf(Team team, List<Employee> members) {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Teamprofil', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text(team.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(team.description),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Team-Informationen'),
          _pdfRow('Team-ID', team.id),
          _pdfRow('Abteilung', team.department ?? 'Nicht zugeordnet'),
          _pdfRow('Status', switch (team.status) {
            TeamStatus.active => 'Aktiv',
            TeamStatus.inactive => 'Inaktiv',
            TeamStatus.onHold => 'Pausiert',
          }),
          _pdfRow('Standort', team.location ?? 'Nicht angegeben'),
          _pdfRow('Budget', team.budget != null ? '${team.budget!.toStringAsFixed(2)} EUR' : 'Nicht festgelegt'),
          _pdfRow('Mitglieder', '${team.memberCount}'),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Mitglieder'),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Name', 'Position', 'Abteilung', 'Status', 'Stunden/Woche'],
            data: members.map((m) => [
              m.fullName,
              m.position,
              m.department,
              m.statusLabel,
              '${m.contractualHours}h',
            ]).toList(),
          ),
          if (team.notes != null && team.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Notizen'),
            pw.Text(team.notes!),
          ],
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Future<void> _exportTeamPdf(Team team, List<Employee> members) async {
    final pdf = _buildTeamPdf(team, members);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Teamprofil_${team.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _printTeamPdf(Team team, List<Employee> members) async {
    final pdf = _buildTeamPdf(team, members);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Teamprofil_${team.name}',
    );
  }

  Future<void> _exportTeamShiftsPdf(Team team, List<Employee> members, List<Shift> shifts) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Schichtplan - ${team.name}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Mitarbeiter', 'Datum', 'Von', 'Bis', 'Typ', 'Status'],
            data: shifts.map((s) {
              final employee = members.where((e) => e.id == s.employeeId).firstOrNull;
              return [
                employee?.fullName ?? s.employeeId,
                '${s.startTime.day}.${s.startTime.month}.${s.startTime.year}',
                '${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}',
                '${s.endTime.hour}:${s.endTime.minute.toString().padLeft(2, '0')}',
                switch (s.type) {
                  ShiftType.regular => 'Regulär',
                  ShiftType.overtime => 'Überstunden',
                  ShiftType.holiday => 'Feiertag',
                  ShiftType.night => 'Nacht',
                  ShiftType.weekend => 'Wochenende',
                },
                switch (s.status) {
                  ShiftStatus.scheduled => 'Geplant',
                  ShiftStatus.inProgress => 'Aktiv',
                  ShiftStatus.completed => 'Erledigt',
                  ShiftStatus.cancelled => 'Abgesagt',
                  ShiftStatus.noShow => 'Nicht erschienen',
                },
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Schichtplan_${team.name.replaceAll(' ', '_')}.pdf',
    );
  }
}

// ──────────────────────────── Calendar Data Source ────────────────────────────

class _TeamCalendarDataSource extends CalendarDataSource {
  _TeamCalendarDataSource({
    required List<Shift> shifts,
    required List<VacationRequest> vacations,
    required List<Timesheet> timesheets,
    required List<Employee> members,
  }) {
    final List<Appointment> allAppointments = [];
    final memberMap = {for (final m in members) m.id: m};

    for (final shift in shifts) {
      final name = memberMap[shift.employeeId]?.fullName ?? 'Unbekannt';
      allAppointments.add(Appointment(
        startTime: shift.startTime,
        endTime: shift.endTime,
        subject: '$name: ${_getShiftTypeLabel(shift.type)}',
        color: _getShiftColor(shift.type),
      ));
    }

    for (final vacation in vacations) {
      if (vacation.status == VacationRequestStatus.rejected ||
          vacation.status == VacationRequestStatus.cancelled) continue;
      final name = memberMap[vacation.employeeId]?.fullName ?? 'Unbekannt';
      allAppointments.add(Appointment(
        startTime: vacation.startDate,
        endTime: vacation.endDate.add(const Duration(hours: 23, minutes: 59)),
        isAllDay: true,
        subject: '$name: ${_getVacationTypeLabel(vacation.type)}',
        color: vacation.status == VacationRequestStatus.pending
            ? _getVacationColor(vacation.type).withOpacity(0.5)
            : _getVacationColor(vacation.type),
      ));
    }

    appointments = allAppointments;
  }

  static Color _getShiftColor(ShiftType type) {
    return switch (type) {
      ShiftType.regular => Colors.blue,
      ShiftType.overtime => Colors.red,
      ShiftType.holiday => Colors.green.shade700,
      ShiftType.night => Colors.indigo,
      ShiftType.weekend => Colors.amber.shade700,
    };
  }

  static String _getShiftTypeLabel(ShiftType type) {
    return switch (type) {
      ShiftType.regular => 'Regulär',
      ShiftType.overtime => 'Überstunden',
      ShiftType.holiday => 'Feiertag',
      ShiftType.night => 'Nachtschicht',
      ShiftType.weekend => 'Wochenende',
    };
  }

  static Color _getVacationColor(VacationType type) {
    return switch (type) {
      VacationType.annual => Colors.green,
      VacationType.sick => Colors.orange,
      VacationType.personal => Colors.purple,
      VacationType.maternity => Colors.pink,
      VacationType.paternity => Colors.teal,
      VacationType.emergency => Colors.deepOrange,
      VacationType.unpaid => Colors.brown,
      VacationType.sabbatical => Colors.cyan,
    };
  }

  static String _getVacationTypeLabel(VacationType type) {
    return switch (type) {
      VacationType.annual => 'Jahresurlaub',
      VacationType.sick => 'Krankenstand',
      VacationType.personal => 'Persönlicher Urlaub',
      VacationType.maternity => 'Mutterschaftsurlaub',
      VacationType.paternity => 'Vaterschaftsurlaub',
      VacationType.emergency => 'Notfall',
      VacationType.unpaid => 'Unbezahlter Urlaub',
      VacationType.sabbatical => 'Sabbatical',
    };
  }
}
