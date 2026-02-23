import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/timesheet_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../models/shift.dart';
import '../../models/vacation_request.dart';
import '../../models/timesheet.dart';
import '../../providers/shift_provider.dart';
import '../../providers/vacation_provider.dart';
import 'widgets/employee_info_card.dart';
import 'widgets/employee_stats_card.dart';
import 'widgets/employee_documents_card.dart';
import 'widgets/employee_timesheet_history.dart';
import 'widgets/employee_form_dialog.dart';
import '../timesheets/widgets/timesheet_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({
    super.key,
    required this.employeeId,
  });

  @override
  ConsumerState<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen>
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
    final employeesAsync = ref.watch(employeesProvider);
    final timesheetsAsync = ref.watch(timesheetsByEmployeeProvider(widget.employeeId));

    return employeesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $error'),
            ],
          ),
        ),
      ),
      data: (employees) {
        final employee = employees.where((e) => e.id == widget.employeeId).firstOrNull;

        if (employee == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mitarbeiter nicht gefunden')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.person_off, size: 64),
                  SizedBox(height: 16),
                  Text('Mitarbeiter wurde nicht gefunden.'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(employee.fullName),
            actions: [
              IconButton(
                onPressed: () => _showEditDialog(employee),
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
                        Text('Profil exportieren'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Symbols.print),
                        SizedBox(width: 8),
                        Text('Profil drucken'),
                      ],
                    ),
                  ),
                  if (employee.status == EmployeeStatus.active)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Symbols.person_off, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Deaktivieren'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Symbols.person_check, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Aktivieren'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) => _handleMenuAction(value, employee),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Symbols.person), text: 'Profil'),
                Tab(icon: Icon(Symbols.analytics), text: 'Statistiken'),
                Tab(icon: Icon(Symbols.schedule), text: 'Zeiten'),
                Tab(icon: Icon(Symbols.folder), text: 'Dokumente'),
                Tab(icon: Icon(Symbols.calendar_month), text: 'Kalender'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(employee),
              _buildStatsTab(employee),
              _buildTimesheetsTab(employee, timesheetsAsync),
              _buildDocumentsTab(employee),
              _buildCalendarTab(employee),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeInfoCard(employee: employee),
          const SizedBox(height: 24),
          _buildPersonalInfoCard(employee),
          const SizedBox(height: 24),
          _buildContractInfoCard(employee),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeStatsCard(employee: employee),
          const SizedBox(height: 24),
          _buildPerformanceCard(employee),
          const SizedBox(height: 24),
          _buildAttendanceCard(employee),
        ],
      ),
    );
  }

  Widget _buildTimesheetsTab(Employee employee, AsyncValue timesheetsAsync) {
    return timesheetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fehler beim Laden der Zeitnachweise: $error'),
          ],
        ),
      ),
      data: (timesheets) => EmployeeTimesheetHistory(
        employee: employee,
        timesheets: timesheets,
      ),
    );
  }

  Widget _buildDocumentsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeDocumentsCard(employee: employee),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(Employee employee) {
    final shiftsAsync = ref.watch(shiftsByEmployeeProvider(employee.id));
    final vacationsAsync = ref.watch(vacationRequestsByEmployeeProvider(employee.id));
    final timesheetsAsync = ref.watch(timesheetsByEmployeeProvider(employee.id));

    final shifts = shiftsAsync.valueOrNull ?? [];
    final vacations = vacationsAsync.valueOrNull ?? [];
    final timesheets = timesheetsAsync.valueOrNull ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Symbols.calendar_month, size: 24),
              const SizedBox(width: 12),
              Text(
                'Kombikalender - ${employee.fullName}',
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
              dataSource: _EmployeeCalendarDataSource(
                shifts: shifts,
                vacations: vacations,
                timesheets: timesheets,
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
        const SizedBox(width: 12),
        _legendItem('Zeiterfassung', Colors.purple),
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

  Widget _buildPersonalInfoCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.badge, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Persönliche Informationen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Mitarbeiter-ID', employee.id),
            _buildInfoRow('Telefon', employee.phone ?? 'Nicht angegeben'),
            _buildInfoRow('E-Mail', employee.email),
            _buildInfoRow('Geburtsdatum', employee.dateOfBirth != null
                ? '${employee.dateOfBirth!.day}.${employee.dateOfBirth!.month}.${employee.dateOfBirth!.year}'
                : 'Nicht angegeben'),
            _buildInfoRow('Adresse', employee.address.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfoCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.work, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Vertragsinformationen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Position', employee.position),
            _buildInfoRow('Abteilung', employee.department),
            _buildInfoRow('Stundenlohn', '${employee.hourlyRate.toStringAsFixed(2)} €'),
            _buildInfoRow('Einstellungsdatum',
                '${employee.hireDate.day}.${employee.hireDate.month}.${employee.hireDate.year}'),
            _buildInfoRow('Status', employee.statusLabel),
            _buildInfoRow('Wochenarbeitszeit', '${employee.contractualHours} Stunden'),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Employee employee) {
    final timesheetsAsync = ref.watch(timesheetsByEmployeeProvider(employee.id));
    final shiftsAsync = ref.watch(shiftsByEmployeeProvider(employee.id));

    final timesheets = timesheetsAsync.valueOrNull ?? [];
    final shifts = shiftsAsync.valueOrNull ?? [];

    // Calculate average weekly hours from last 4 weeks of timesheets
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final recentTimesheets = timesheets.where((ts) =>
      ts.startDate.isAfter(fourWeeksAgo)).toList();
    final totalHours = recentTimesheets.fold(0.0,
      (sum, ts) => sum + ts.calculatedTotalHours);
    final weeks = recentTimesheets.isEmpty ? 1 :
      (now.difference(recentTimesheets.map((ts) => ts.startDate).reduce(
        (a, b) => a.isBefore(b) ? a : b).isAfter(fourWeeksAgo) ?
        recentTimesheets.map((ts) => ts.startDate).reduce(
          (a, b) => a.isBefore(b) ? a : b) : fourWeeksAgo
      ).inDays / 7).ceil().clamp(1, 4);
    final avgWeeklyHours = totalHours / weeks;

    // Calculate overtime this month
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTimesheets = timesheets.where((ts) =>
      ts.startDate.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
    final overtimeHours = monthTimesheets.fold(0.0,
      (sum, ts) => sum + ts.calculatedOvertimeHours);

    // Calculate punctuality from shifts (actualStartTime <= startTime)
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentShifts = shifts.where((s) =>
      s.startTime.isAfter(thirtyDaysAgo) &&
      (s.status == ShiftStatus.completed || s.status == ShiftStatus.inProgress)).toList();
    final punctualShifts = recentShifts.where((s) =>
      s.actualStartTime != null &&
      !s.actualStartTime!.isAfter(s.startTime.add(const Duration(minutes: 5)))).length;
    final punctuality = recentShifts.isEmpty ? 100.0 :
      (punctualShifts / recentShifts.length * 100);

    // Calculate attendance (completed shifts vs scheduled shifts this month)
    final monthShifts = shifts.where((s) =>
      s.startTime.isAfter(monthStart.subtract(const Duration(days: 1))) &&
      s.startTime.isBefore(now)).toList();
    final completedShifts = monthShifts.where((s) =>
      s.status == ShiftStatus.completed || s.status == ShiftStatus.inProgress).length;
    final totalScheduled = monthShifts.length;

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
                  'Leistungsübersicht',
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
                    'Durchschnittliche Arbeitszeit',
                    '${avgWeeklyHours.toStringAsFixed(1)}h',
                    'pro Woche',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Überstunden',
                    '${overtimeHours.toStringAsFixed(1)}h',
                    'diesen Monat',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Pünktlichkeit',
                    '${punctuality.toStringAsFixed(0)}%',
                    'letzte 30 Tage',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Anwesenheit',
                    '$completedShifts/$totalScheduled',
                    'Arbeitstage',
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

  Widget _buildAttendanceCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.calendar_month, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Anwesenheitskalender',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: SfCalendar(
                view: CalendarView.month,
                dataSource: _EmployeeCalendarDataSource(
                  shifts: ref.watch(shiftsByEmployeeProvider(employee.id)).valueOrNull ?? [],
                  vacations: ref.watch(vacationRequestsByEmployeeProvider(employee.id)).valueOrNull ?? [],
                  timesheets: ref.watch(timesheetsByEmployeeProvider(employee.id)).valueOrNull ?? [],
                ),
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  showAgenda: false,
                  numberOfWeeksInView: 6,
                ),
                firstDayOfWeek: 1,
                showNavigationArrow: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        employee: employee,
        onSave: (updatedEmployee) {
          ref.read(employeesProvider.notifier).updateEmployee(updatedEmployee);
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(content: Text('Mitarbeiter wurde aktualisiert')),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, Employee employee) {
    switch (action) {
      case 'export':
        _exportProfilePdf(employee);
        break;
      case 'print':
        _printProfile(employee);
        break;
      case 'activate':
      case 'deactivate':
        _toggleEmployeeStatus(employee);
        break;
    }
  }

  pw.Document _buildProfilePdf(Employee employee) {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Mitarbeiterprofil', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text('${employee.fullName}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('${employee.position} - ${employee.department}'),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Persönliche Informationen'),
          _pdfRow('Mitarbeiter-ID', employee.id),
          _pdfRow('Mitarbeiternummer', employee.employeeNumber),
          _pdfRow('E-Mail', employee.email),
          _pdfRow('Telefon', employee.phone ?? 'Nicht angegeben'),
          _pdfRow('Geburtsdatum', employee.dateOfBirth != null
              ? '${employee.dateOfBirth!.day}.${employee.dateOfBirth!.month}.${employee.dateOfBirth!.year}'
              : 'Nicht angegeben'),
          _pdfRow('Adresse', employee.address.fullAddress),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Vertragsinformationen'),
          _pdfRow('Position', employee.position),
          _pdfRow('Abteilung', employee.department),
          _pdfRow('Vertragsart', employee.contractType.name),
          _pdfRow('Stundenlohn', '${employee.hourlyRate.toStringAsFixed(2)} EUR'),
          _pdfRow('Wochenarbeitszeit', '${employee.contractualHours} Stunden'),
          _pdfRow('Einstellungsdatum', '${employee.hireDate.day}.${employee.hireDate.month}.${employee.hireDate.year}'),
          _pdfRow('Status', employee.statusLabel),
          if (employee.notes != null && employee.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Notizen'),
            pw.Text(employee.notes!),
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

  Future<void> _exportProfilePdf(Employee employee) async {
    final pdf = _buildProfilePdf(employee);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Mitarbeiterprofil_${employee.lastName}_${employee.firstName}.pdf',
    );
  }

  Future<void> _printProfile(Employee employee) async {
    final pdf = _buildProfilePdf(employee);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mitarbeiterprofil_${employee.fullName}',
    );
  }

  void _toggleEmployeeStatus(Employee employee) {
    final newStatus = employee.status == EmployeeStatus.active
        ? EmployeeStatus.inactive
        : EmployeeStatus.active;

    final updatedEmployee = employee.copyWith(status: newStatus);
    ref.read(employeesProvider.notifier).updateEmployee(updatedEmployee);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == EmployeeStatus.active
              ? 'Mitarbeiter wurde aktiviert'
              : 'Mitarbeiter wurde deaktiviert'
        ),
      ),
    );
  }
}

class _EmployeeCalendarDataSource extends CalendarDataSource {
  _EmployeeCalendarDataSource({
    required List<Shift> shifts,
    required List<VacationRequest> vacations,
    required List<Timesheet> timesheets,
  }) {
    final List<Appointment> allAppointments = [];

    // Add shifts
    for (final shift in shifts) {
      allAppointments.add(Appointment(
        startTime: shift.startTime,
        endTime: shift.endTime,
        subject: 'Schicht: ${_getShiftTypeLabel(shift.type)}',
        color: _getShiftColor(shift.type),
        notes: shift.description,
      ));
    }

    // Add vacations
    for (final vacation in vacations) {
      if (vacation.status == VacationRequestStatus.rejected ||
          vacation.status == VacationRequestStatus.cancelled) continue;
      allAppointments.add(Appointment(
        startTime: vacation.startDate,
        endTime: vacation.endDate.add(const Duration(hours: 23, minutes: 59)),
        isAllDay: true,
        subject: _getVacationTypeLabel(vacation.type),
        color: vacation.status == VacationRequestStatus.pending
            ? _getVacationColor(vacation.type).withOpacity(0.5)
            : _getVacationColor(vacation.type),
        notes: vacation.reason,
      ));
    }

    // Add timesheet entries
    for (final ts in timesheets) {
      for (final entry in ts.entries) {
        allAppointments.add(Appointment(
          startTime: entry.startTime,
          endTime: entry.endTime,
          subject: 'Zeit: ${_getEntryTypeLabel(entry.type)}',
          color: _getEntryColor(entry.type),
          notes: entry.description,
        ));
      }
    }

    appointments = allAppointments;
  }

  static Color _getShiftColor(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return Colors.blue;
      case ShiftType.overtime:
        return Colors.red;
      case ShiftType.holiday:
        return Colors.green.shade700;
      case ShiftType.night:
        return Colors.indigo;
      case ShiftType.weekend:
        return Colors.amber.shade700;
    }
  }

  static String _getShiftTypeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return 'Regulär';
      case ShiftType.overtime:
        return 'Überstunden';
      case ShiftType.holiday:
        return 'Feiertag';
      case ShiftType.night:
        return 'Nachtschicht';
      case ShiftType.weekend:
        return 'Wochenende';
    }
  }

  static Color _getVacationColor(VacationType type) {
    switch (type) {
      case VacationType.annual:
        return Colors.green;
      case VacationType.sick:
        return Colors.orange;
      case VacationType.personal:
        return Colors.purple;
      case VacationType.maternity:
        return Colors.pink;
      case VacationType.paternity:
        return Colors.teal;
      case VacationType.emergency:
        return Colors.deepOrange;
      case VacationType.unpaid:
        return Colors.brown;
      case VacationType.sabbatical:
        return Colors.cyan;
    }
  }

  static String _getVacationTypeLabel(VacationType type) {
    switch (type) {
      case VacationType.annual:
        return 'Jahresurlaub';
      case VacationType.sick:
        return 'Krankenstand';
      case VacationType.personal:
        return 'Persönlicher Urlaub';
      case VacationType.maternity:
        return 'Mutterschaftsurlaub';
      case VacationType.paternity:
        return 'Vaterschaftsurlaub';
      case VacationType.emergency:
        return 'Notfall';
      case VacationType.unpaid:
        return 'Unbezahlter Urlaub';
      case VacationType.sabbatical:
        return 'Sabbatical';
    }
  }

  static Color _getEntryColor(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return Colors.purple.shade300;
      case TimesheetEntryType.overtime:
        return Colors.red.shade300;
      case TimesheetEntryType.travel:
        return Colors.orange.shade300;
      case TimesheetEntryType.break_:
        return Colors.grey;
      case TimesheetEntryType.training:
        return Colors.green.shade300;
      case TimesheetEntryType.administrative:
        return Colors.purple.shade200;
    }
  }

  static String _getEntryTypeLabel(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return 'Regulär';
      case TimesheetEntryType.overtime:
        return 'Überstunden';
      case TimesheetEntryType.travel:
        return 'Reise';
      case TimesheetEntryType.break_:
        return 'Pause';
      case TimesheetEntryType.training:
        return 'Schulung';
      case TimesheetEntryType.administrative:
        return 'Verwaltung';
    }
  }
}