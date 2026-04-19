import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';

class EmployeeInfoCard extends StatelessWidget {
  final Employee employee;

  const EmployeeInfoCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar and Basic Info
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getStatusColor(context, employee.status),
                  child: Text(
                    _getInitials(employee.fullName),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.position,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(employee.status),
                            size: 16,
                            color: _getStatusColor(context, employee.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            employee.statusLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(context, employee.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Abteilung',
                    employee.department,
                    Symbols.business,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Stundenlohn',
                    '${employee.hourlyRate.toStringAsFixed(2)} €',
                    Symbols.euro,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Seit',
                    _formatDate(employee.hireDate),
                    Symbols.calendar_today,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Wochenstunden',
                    '${employee.contractualHours}h',
                    Symbols.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names.first.substring(0, 1).toUpperCase();
    }
    return 'NA';
  }

  IconData _getStatusIcon(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return Symbols.check_circle;
      case EmployeeStatus.inactive:
        return Symbols.pause_circle;
      case EmployeeStatus.onLeave:
        return Symbols.schedule;
      case EmployeeStatus.terminated:
        return Symbols.cancel;
    }
  }

  Color _getStatusColor(BuildContext context, EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return Colors.green;
      case EmployeeStatus.inactive:
        return Colors.orange;
      case EmployeeStatus.onLeave:
        return Colors.blue;
      case EmployeeStatus.terminated:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '–';
    return '${date.day}.${date.month}.${date.year}';
  }
}