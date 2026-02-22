import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../../models/shift.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';

class ShiftCard extends ConsumerWidget {
  final Shift shift;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;

  const ShiftCard({
    super.key,
    required this.shift,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStart,
    this.onEnd,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeByIdProvider(shift.employeeId));

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
                      _getShiftTypeIcon(shift.type),
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
                      if (shift.status == ShiftStatus.scheduled && shift.isToday) ...[
                        PopupMenuItem(
                          value: 'start',
                          child: Row(
                            children: [
                              const Icon(Symbols.play_arrow, size: 18, color: Colors.green),
                              const SizedBox(width: 12),
                              const Text('Schicht starten', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                      if (shift.status == ShiftStatus.inProgress) ...[
                        PopupMenuItem(
                          value: 'end',
                          child: Row(
                            children: [
                              const Icon(Symbols.stop, size: 18, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Text('Schicht beenden', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                      if (shift.status == ShiftStatus.scheduled) ...[
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
                        PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              const Icon(Symbols.cancel, size: 18, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Text('Absagen', style: TextStyle(color: Colors.orange)),
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
                        case 'start':
                          onStart?.call();
                          break;
                        case 'end':
                          onEnd?.call();
                          break;
                        case 'cancel':
                          onCancel?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
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
              Row(
                children: [
                  Icon(
                    Symbols.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat.Hm().format(shift.startTime)} - ${DateFormat.Hm().format(shift.endTime)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Symbols.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${shift.startTime.day}.${shift.startTime.month}.${shift.startTime.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
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
              if (shift.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Symbols.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shift.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
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
                      color: _getTypeColor(shift.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTypeColor(shift.type).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getTypeLabel(shift.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getTypeColor(shift.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Symbols.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shift.scheduledHours.toStringAsFixed(1)}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (shift.actualHours != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tatsächlich: ${shift.actualHours!.toStringAsFixed(1)}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
        _getStatusLabel(shift.status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getStatusColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (shift.status) {
      case ShiftStatus.scheduled:
        return shift.isOverdue
            ? Theme.of(context).colorScheme.error
            : Colors.blue;
      case ShiftStatus.inProgress:
        return Colors.green;
      case ShiftStatus.completed:
        return Colors.grey;
      case ShiftStatus.cancelled:
        return Colors.orange;
      case ShiftStatus.noShow:
        return Theme.of(context).colorScheme.error;
    }
  }

  Color _getTypeColor(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return Colors.blue;
      case ShiftType.overtime:
        return Colors.purple;
      case ShiftType.holiday:
        return Colors.red;
      case ShiftType.night:
        return Colors.indigo;
      case ShiftType.weekend:
        return Colors.orange;
    }
  }

  IconData _getShiftTypeIcon(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return Symbols.schedule;
      case ShiftType.overtime:
        return Symbols.more_time;
      case ShiftType.holiday:
        return Symbols.celebration;
      case ShiftType.night:
        return Symbols.dark_mode;
      case ShiftType.weekend:
        return Symbols.weekend;
    }
  }

  String _getStatusLabel(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.scheduled:
        return shift.isOverdue ? 'Überfällig' : 'Geplant';
      case ShiftStatus.inProgress:
        return 'Aktiv';
      case ShiftStatus.completed:
        return 'Abgeschlossen';
      case ShiftStatus.cancelled:
        return 'Abgesagt';
      case ShiftStatus.noShow:
        return 'Nicht erschienen';
    }
  }

  String _getTypeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return 'Normal';
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
}