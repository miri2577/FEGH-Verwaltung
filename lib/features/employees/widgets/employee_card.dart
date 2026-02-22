import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';
import '../employee_profile_screen.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmployeeProfileScreen(employeeId: employee.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      _getInitials(employee.fullName),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '#${employee.employeeNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Symbols.work, employee.position),
              const SizedBox(height: 4),
              _buildInfoRow(Symbols.business, employee.department),
              const SizedBox(height: 4),
              _buildInfoRow(Symbols.email, employee.email),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${employee.hoursPerWeek}h/Woche',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '€${employee.hourlyRate.toStringAsFixed(2)}/h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Symbols.edit, size: 18),
                        tooltip: 'Bearbeiten',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Symbols.delete, size: 18),
                        tooltip: 'Löschen',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color foregroundColor;
    String label;

    switch (employee.status) {
      case EmployeeStatus.active:
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        label = 'Aktiv';
        break;
      case EmployeeStatus.inactive:
        backgroundColor = Colors.grey.shade100;
        foregroundColor = Colors.grey.shade800;
        label = 'Inaktiv';
        break;
      case EmployeeStatus.onLeave:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade800;
        label = 'Beurlaubt';
        break;
      case EmployeeStatus.terminated:
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade800;
        label = 'Gekündigt';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'MA';
  }
}