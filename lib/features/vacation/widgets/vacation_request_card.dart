import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../../models/vacation_request.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';

class VacationRequestCard extends ConsumerWidget {
  final VacationRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const VacationRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeByIdProvider(request.employeeId));

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getVacationTypeIcon(request.type),
                      size: 20,
                      color: _getStatusColor(context),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(context),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Symbols.info, size: 18),
                            const SizedBox(width: 12),
                            const Text('Details'),
                          ],
                        ),
                      ),
                      if (request.isPending) ...[
                        PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              const Icon(Symbols.check_circle, size: 18, color: Colors.green),
                              const SizedBox(width: 12),
                              const Text('Genehmigen', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              const Icon(Symbols.cancel, size: 18, color: Colors.red),
                              const SizedBox(width: 12),
                              const Text('Ablehnen', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      if (request.isPending || request.isApproved) ...[
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Symbols.edit, size: 18),
                              const SizedBox(width: 12),
                              const Text('Bearbeiten'),
                            ],
                          ),
                        ),
                      ],
                      if (request.isPending || (request.isApproved && request.isUpcoming)) ...[
                        PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              const Icon(Symbols.cancel, size: 18, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Text('Stornieren', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Symbols.delete,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          onTap?.call();
                          break;
                        case 'approve':
                          onApprove?.call();
                          break;
                        case 'reject':
                          onReject?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'cancel':
                          onCancel?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    child: const Icon(Symbols.more_vert, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              employeeAsync != null
                  ? Row(
                      children: [
                        Icon(
                          Symbols.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employeeAsync.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Symbols.person_off,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mitarbeiter nicht gefunden',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Symbols.calendar_month,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat.yMd('de_DE').format(request.startDate)} - ${DateFormat.yMd('de_DE').format(request.endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.totalDays} ${request.totalDays == 1 ? 'Tag' : 'Tage'} (${request.workingDays} Arbeitstage)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.description,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(request.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTypeColor(request.type).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getTypeLabel(request.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getTypeColor(request.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (request.isApproved && request.approvedAt != null) ...[
                    Icon(
                      Symbols.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMd('de_DE').format(request.approvedAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (request.isRejected) ...[
                    Icon(
                      Symbols.cancel,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Abgelehnt',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (request.isPending) ...[
                    Icon(
                      Symbols.pending,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMd('de_DE').format(request.requestDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (request.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.warning,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.rejectionReason!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusLabel(request.status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getStatusColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (request.status) {
      case VacationRequestStatus.pending:
        return Colors.orange;
      case VacationRequestStatus.approved:
        return Colors.green;
      case VacationRequestStatus.rejected:
        return Colors.red;
      case VacationRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getTypeColor(VacationType type) {
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
        return Colors.indigo;
      case VacationType.emergency:
        return Colors.orange;
      case VacationType.unpaid:
        return Colors.grey;
      case VacationType.sabbatical:
        return Colors.teal;
    }
  }

  IconData _getVacationTypeIcon(VacationType type) {
    switch (type) {
      case VacationType.annual:
        return Symbols.beach_access;
      case VacationType.sick:
        return Symbols.medical_services;
      case VacationType.personal:
        return Symbols.person;
      case VacationType.maternity:
        return Symbols.child_care;
      case VacationType.paternity:
        return Symbols.family_restroom;
      case VacationType.emergency:
        return Symbols.emergency;
      case VacationType.unpaid:
        return Symbols.money_off;
      case VacationType.sabbatical:
        return Symbols.school;
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