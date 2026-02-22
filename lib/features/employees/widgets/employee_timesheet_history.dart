import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';
import '../../timesheets/widgets/timesheet_card.dart';

class EmployeeTimesheetHistory extends StatefulWidget {
  final Employee employee;
  final List timesheets;

  const EmployeeTimesheetHistory({
    super.key,
    required this.employee,
    required this.timesheets,
  });

  @override
  State<EmployeeTimesheetHistory> createState() => _EmployeeTimesheetHistoryState();
}

class _EmployeeTimesheetHistoryState extends State<EmployeeTimesheetHistory> {
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  @override
  Widget build(BuildContext context) {
    final filteredTimesheets = _getFilteredTimesheets();
    final sortedTimesheets = _getSortedTimesheets(filteredTimesheets);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Filter and Sort Controls
          _buildControls(),
          const SizedBox(height: 20),

          // Summary Stats
          _buildSummaryStats(),
          const SizedBox(height: 20),

          // Timesheet List
          Expanded(
            child: sortedTimesheets.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: sortedTimesheets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final timesheet = sortedTimesheets[index];
                      return TimesheetCard(
                        timesheet: timesheet,
                        onTap: () {
                          // Navigation to timesheet detail is handled by the card itself
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Filter Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Alle Zeitnachweise')),
                      DropdownMenuItem(value: 'draft', child: Text('Entwürfe')),
                      DropdownMenuItem(value: 'submitted', child: Text('Eingereicht')),
                      DropdownMenuItem(value: 'approved', child: Text('Genehmigt')),
                      DropdownMenuItem(value: 'rejected', child: Text('Abgelehnt')),
                      DropdownMenuItem(value: 'finalized', child: Text('Abgeschlossen')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Sort Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sortierung',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Neueste zuerst')),
                      DropdownMenuItem(value: 'oldest', child: Text('Älteste zuerst')),
                      DropdownMenuItem(value: 'hours_high', child: Text('Meiste Stunden')),
                      DropdownMenuItem(value: 'hours_low', child: Text('Wenigste Stunden')),
                      DropdownMenuItem(value: 'status', child: Text('Nach Status')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSort = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final filteredTimesheets = _getFilteredTimesheets();
    final totalHours = filteredTimesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedTotalHours);
    final totalPay = filteredTimesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedTotalPay);
    final overtimeHours = filteredTimesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedOvertimeHours);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.analytics, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Zusammenfassung (${_getFilterLabel()})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    'Zeitnachweise',
                    '${filteredTimesheets.length}',
                    Symbols.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Stunden gesamt',
                    '${totalHours.toStringAsFixed(1)}h',
                    Symbols.timer,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Überstunden',
                    '${overtimeHours.toStringAsFixed(1)}h',
                    Symbols.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Vergütung',
                    '${totalPay.toStringAsFixed(0)} €',
                    Symbols.euro,
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

  Widget _buildSummaryTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'all' ? Symbols.schedule : Symbols.filter_alt_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Noch keine Zeitnachweise vorhanden'
                : 'Keine Zeitnachweise mit diesem Filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Zeitnachweise werden hier angezeigt, sobald welche erstellt wurden.'
                : 'Versuchen Sie einen anderen Filter oder erstellen Sie neue Zeitnachweise.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter != 'all') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              icon: const Icon(Symbols.filter_alt_off),
              label: const Text('Filter zurücksetzen'),
            ),
          ],
        ],
      ),
    );
  }

  List _getFilteredTimesheets() {
    if (_selectedFilter == 'all') {
      return widget.timesheets;
    }
    return widget.timesheets.where((timesheet) {
      return timesheet.status.toString().split('.').last == _selectedFilter;
    }).toList();
  }

  List _getSortedTimesheets(List timesheets) {
    final sortedList = List.from(timesheets);

    switch (_selectedSort) {
      case 'newest':
        sortedList.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case 'oldest':
        sortedList.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'hours_high':
        sortedList.sort((a, b) => b.calculatedTotalHours.compareTo(a.calculatedTotalHours));
        break;
      case 'hours_low':
        sortedList.sort((a, b) => a.calculatedTotalHours.compareTo(b.calculatedTotalHours));
        break;
      case 'status':
        final statusOrder = ['draft', 'submitted', 'approved', 'rejected', 'finalized'];
        sortedList.sort((a, b) {
          final aIndex = statusOrder.indexOf(a.status.toString().split('.').last);
          final bIndex = statusOrder.indexOf(b.status.toString().split('.').last);
          return aIndex.compareTo(bIndex);
        });
        break;
    }

    return sortedList;
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'all':
        return 'Alle Zeitnachweise';
      case 'draft':
        return 'Entwürfe';
      case 'submitted':
        return 'Eingereichte';
      case 'approved':
        return 'Genehmigte';
      case 'rejected':
        return 'Abgelehnte';
      case 'finalized':
        return 'Abgeschlossene';
      default:
        return 'Gefilterte Zeitnachweise';
    }
  }
}