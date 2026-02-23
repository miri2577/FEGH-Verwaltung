import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/vacation_request.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../providers/vacation_provider.dart';
import '../../providers/employee_provider.dart';
import 'widgets/vacation_request_card.dart';
import 'widgets/vacation_request_form_dialog.dart';

class VacationScreen extends ConsumerStatefulWidget {
  const VacationScreen({super.key});

  @override
  ConsumerState<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends ConsumerState<VacationScreen> with SingleTickerProviderStateMixin {
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
    final vacationRequestsAsyncValue = ref.watch(vacationRequestsProvider);
    final requestCount = ref.watch(vacationRequestCountProvider);
    final pendingApprovalCount = ref.watch(pendingApprovalCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.beach_access,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Urlaubsplanung',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$requestCount Anträge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (pendingApprovalCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.pending_actions,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingApprovalCount ausstehend',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _refreshVacationRequests(ref),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showAddVacationRequestDialog(),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Urlaubsantrag'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ausstehend'),
                Tab(text: 'Genehmigt'),
                Tab(text: 'Aktiv'),
                Tab(text: 'Alle'),
                Tab(text: 'Kalender'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingRequests(),
                  _buildApprovedRequests(),
                  _buildActiveRequests(),
                  _buildAllRequests(vacationRequestsAsyncValue),
                  _buildCalendarView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    return Consumer(
      builder: (context, ref, child) {
        final pendingRequests = ref.watch(pendingVacationRequestsProvider);
        return pendingRequests.when(
          data: (requests) => requests.isEmpty
              ? _buildEmptyState('Keine ausstehenden Anträge', 'Alle Urlaubsanträge wurden bearbeitet.')
              : _buildRequestsList(requests),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildApprovedRequests() {
    return Consumer(
      builder: (context, ref, child) {
        final approvedRequests = ref.watch(approvedVacationRequestsProvider);
        return approvedRequests.when(
          data: (requests) => requests.isEmpty
              ? _buildEmptyState('Keine genehmigten Anträge', 'Es wurden noch keine Urlaubsanträge genehmigt.')
              : _buildRequestsList(requests),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildActiveRequests() {
    return Consumer(
      builder: (context, ref, child) {
        final activeRequests = ref.watch(activeVacationRequestsProvider);
        return activeRequests.when(
          data: (requests) => requests.isEmpty
              ? _buildEmptyState('Keine aktiven Urlaubszeiten', 'Derzeit ist niemand im Urlaub.')
              : _buildRequestsList(requests),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildAllRequests(AsyncValue<List<VacationRequest>> requestsAsyncValue) {
    return requestsAsyncValue.when(
      data: (requests) => requests.isEmpty
          ? _buildEmptyState('Keine Urlaubsanträge vorhanden', 'Erstellen Sie den ersten Urlaubsantrag, um zu beginnen.')
          : _buildRequestsList(requests),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildRequestsList(List<VacationRequest> requests) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return VacationRequestCard(
          request: request,
          onTap: () => _showRequestDetails(request),
          onEdit: () => _showEditRequestDialog(request),
          onDelete: () => _showDeleteConfirmation(request),
          onApprove: () => _approveRequest(request.id),
          onReject: () => _showRejectDialog(request),
          onCancel: () => _cancelRequest(request.id),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    final vacationRequestsAsync = ref.watch(vacationRequestsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return vacationRequestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
      data: (requests) {
        final employees = employeesAsync.valueOrNull ?? [];
        return SfCalendar(
          view: CalendarView.month,
          dataSource: _VacationCalendarDataSource(requests, employees),
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showAgenda: true,
            agendaViewHeight: 200,
            numberOfWeeksInView: 6,
          ),
          firstDayOfWeek: 1,
          showNavigationArrow: true,
          showDatePickerButton: true,
          allowDragAndDrop: true,
          onDragEnd: (details) {
            if (details.appointment != null && details.droppingTime != null) {
              final appointment = details.appointment! as Appointment;
              final request = requests.firstWhere(
                (r) => r.id == appointment.id,
                orElse: () => requests.first,
              );
              final duration = request.endDate.difference(request.startDate);
              final newStart = DateTime(
                details.droppingTime!.year,
                details.droppingTime!.month,
                details.droppingTime!.day,
              );
              final newEnd = newStart.add(duration);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Urlaub verschoben auf ${newStart.day}.${newStart.month}.${newStart.year} - ${newEnd.day}.${newEnd.month}.${newEnd.year}'),
                  action: SnackBarAction(
                    label: 'Rückgängig',
                    onPressed: () {},
                  ),
                ),
              );
            }
          },
          onTap: (details) {
            if (details.appointments != null && details.appointments!.isNotEmpty) {
              final appointment = details.appointments!.first as Appointment;
              final request = requests.where((r) => r.id == appointment.id).firstOrNull;
              if (request != null) {
                _showRequestDetails(request);
              }
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.beach_access,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.error,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden der Urlaubsanträge',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _refreshVacationRequests(ref),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshVacationRequests(WidgetRef ref) {
    ref.read(vacationRequestsProvider.notifier).refresh();
  }

  void _showAddVacationRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => const VacationRequestFormDialog(),
    );
  }

  void _showEditRequestDialog(VacationRequest request) {
    showDialog(
      context: context,
      builder: (context) => VacationRequestFormDialog(request: request),
    );
  }

  void _showRequestDetails(VacationRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urlaubsantrag Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mitarbeiter ID: ${request.employeeId}'),
              Text('Typ: ${_getTypeLabel(request.type)}'),
              Text('Von: ${DateFormat.yMd('de_DE').format(request.startDate)}'),
              Text('Bis: ${DateFormat.yMd('de_DE').format(request.endDate)}'),
              Text('Tage gesamt: ${request.totalDays}'),
              Text('Arbeitstage: ${request.workingDays}'),
              Text('Status: ${_getStatusLabel(request.status)}'),
              Text('Begründung: ${request.reason}'),
              if (request.notes != null) Text('Notizen: ${request.notes}'),
              Text('Antragsdatum: ${DateFormat.yMd('de_DE').format(request.requestDate)}'),
              if (request.approvedBy != null) Text('Genehmigt von: ${request.approvedBy}'),
              if (request.approvedAt != null) Text('Genehmigt am: ${DateFormat.yMd('de_DE').format(request.approvedAt!)}'),
              if (request.rejectionReason != null) Text('Ablehnungsgrund: ${request.rejectionReason}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VacationRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urlaubsantrag löschen'),
        content: const Text('Möchten Sie diesen Urlaubsantrag wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(vacationRequestsProvider.notifier).deleteVacationRequest(request.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(VacationRequest request) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urlaubsantrag ablehnen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Grund für die Ablehnung:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Begründung eingeben...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                await ref.read(vacationRequestsProvider.notifier).rejectVacationRequest(
                  request.id,
                  reasonController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Urlaubsantrag abgelehnt'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }

  void _approveRequest(String requestId) async {
    await ref.read(vacationRequestsProvider.notifier).approveVacationRequest(
      requestId,
      'admin', // TODO: Get actual user ID
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Urlaubsantrag genehmigt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelRequest(String requestId) async {
    await ref.read(vacationRequestsProvider.notifier).cancelVacationRequest(requestId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Urlaubsantrag storniert'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _getStatusLabel(VacationRequestStatus status) {
    switch (status) {
      case VacationRequestStatus.pending:
        return 'Ausstehend';
      case VacationRequestStatus.approved:
        return 'Genehmigt';
      case VacationRequestStatus.rejected:
        return 'Abgelehnt';
      case VacationRequestStatus.cancelled:
        return 'Storniert';
    }
  }

  String _getTypeLabel(VacationType type) {
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
}

class _VacationCalendarDataSource extends CalendarDataSource {
  _VacationCalendarDataSource(List<VacationRequest> requests, List<dynamic> employees) {
    appointments = requests.map((request) {
      String employeeName = 'Mitarbeiter ${request.employeeId}';
      for (final emp in employees) {
        if (emp.id == request.employeeId) {
          employeeName = emp.fullName;
          break;
        }
      }
      return Appointment(
        id: request.id,
        startTime: request.startDate,
        endTime: request.endDate.add(const Duration(hours: 23, minutes: 59)),
        isAllDay: true,
        subject: '$employeeName - ${_getTypeLabel(request.type)}',
        color: _getColor(request),
        notes: request.reason,
      );
    }).toList();
  }

  static Color _getColor(VacationRequest request) {
    if (request.status == VacationRequestStatus.pending) {
      return _getTypeColor(request.type).withOpacity(0.5);
    }
    if (request.status == VacationRequestStatus.rejected) {
      return Colors.grey;
    }
    if (request.status == VacationRequestStatus.cancelled) {
      return Colors.grey.shade400;
    }
    return _getTypeColor(request.type);
  }

  static Color _getTypeColor(VacationType type) {
    switch (type) {
      case VacationType.annual:
        return Colors.blue;
      case VacationType.sick:
        return Colors.red;
      case VacationType.personal:
        return Colors.purple;
      case VacationType.maternity:
        return Colors.pink;
      case VacationType.paternity:
        return Colors.teal;
      case VacationType.emergency:
        return Colors.orange;
      case VacationType.unpaid:
        return Colors.brown;
      case VacationType.sabbatical:
        return Colors.indigo;
    }
  }

  static String _getTypeLabel(VacationType type) {
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
}