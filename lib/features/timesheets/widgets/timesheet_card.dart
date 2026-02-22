import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/timesheet.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../timesheet_detail_screen.dart';

class TimesheetCard extends ConsumerWidget {
  final Timesheet timesheet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSubmit;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const TimesheetCard({
    super.key,
    required this.timesheet,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSubmit,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    Employee? employee;
    employeesAsync.whenData((employees) {
      try {
        employee = employees.firstWhere((e) => e.id == timesheet.employeeId);
      } catch (e) {
        employee = null;
      }
    });

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TimesheetDetailScreen(timesheetId: timesheet.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getStatusIcon(timesheet.status),
                    size: 20,
                    color: _getStatusColor(context, timesheet.status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      employee?.fullName ?? 'Unbekannter Mitarbeiter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => _buildMenuItems(context),
                    onSelected: _handleMenuSelection,
                    child: Icon(
                      Symbols.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(context, timesheet.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(context, timesheet.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  timesheet.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(context, timesheet.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date Range
              Row(
                children: [
                  Icon(
                    Symbols.date_range,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(timesheet.startDate)} - ${_formatDate(timesheet.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hours and Pay
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${timesheet.calculatedTotalHours.toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Symbols.euro,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${timesheet.calculatedTotalPay.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Entries Count
              Row(
                children: [
                  Icon(
                    Symbols.list_alt,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${timesheet.entries.length} Einträge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (timesheet.calculatedOvertimeHours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.warningContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${timesheet.calculatedOvertimeHours.toStringAsFixed(1)}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onWarningContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Action Buttons
              if (timesheet.canBeEdited || timesheet.canBeSubmitted || timesheet.canBeApproved)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (timesheet.canBeSubmitted)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onSubmit,
                            icon: const Icon(Symbols.send, size: 16),
                            label: const Text('Einreichen'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      if (timesheet.canBeApproved) ...[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Symbols.check, size: 16),
                            label: const Text('Genehmigen'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Symbols.close, size: 16),
                          label: const Text('Ablehnen'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(color: Theme.of(context).colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
      const PopupMenuItem(
        value: 'view',
        child: Row(
          children: [
            Icon(Symbols.visibility, size: 18),
            SizedBox(width: 8),
            Text('Details anzeigen'),
          ],
        ),
      ),
    );

    if (timesheet.canBeEdited) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Symbols.edit, size: 18),
              SizedBox(width: 8),
              Text('Bearbeiten'),
            ],
          ),
        ),
      );
    }

    if (timesheet.status == TimesheetStatus.draft) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Symbols.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Löschen', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'view':
        onTap?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  IconData _getStatusIcon(TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return Symbols.edit_note;
      case TimesheetStatus.submitted:
        return Symbols.send;
      case TimesheetStatus.approved:
        return Symbols.check_circle;
      case TimesheetStatus.rejected:
        return Symbols.cancel;
      case TimesheetStatus.finalized:
        return Symbols.lock;
    }
  }

  Color _getStatusColor(BuildContext context, TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return Theme.of(context).colorScheme.outline;
      case TimesheetStatus.submitted:
        return Colors.orange;
      case TimesheetStatus.approved:
        return Colors.green;
      case TimesheetStatus.rejected:
        return Theme.of(context).colorScheme.error;
      case TimesheetStatus.finalized:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

// Extension for warning container color (if not available in theme)
extension ColorSchemeExtension on ColorScheme {
  Color get warningContainer => const Color(0xFFFFF4E6);
  Color get onWarningContainer => const Color(0xFF8B4513);
}