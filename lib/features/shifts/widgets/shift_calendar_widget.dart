import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/shift.dart';
import '../../../models/employee.dart';

class ShiftCalendarWidget extends StatelessWidget {
  final List<Shift> shifts;
  final List<Employee> employees;
  final DateTime selectedDate;
  final String viewMode;
  final List<String> selectedEmployeeIds;
  final Function(Shift) onShiftTap;
  final Function(DateTime) onTimeSlotTap;
  final Function(Shift, DateTime) onShiftDrag;

  const ShiftCalendarWidget({
    super.key,
    required this.shifts,
    required this.employees,
    required this.selectedDate,
    required this.viewMode,
    required this.selectedEmployeeIds,
    required this.onShiftTap,
    required this.onTimeSlotTap,
    required this.onShiftDrag,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case 'day':
        return _buildDayView(context);
      case 'week':
        return _buildWeekView(context);
      case 'month':
        return _buildMonthView(context);
      default:
        return _buildWeekView(context);
    }
  }

  Widget _buildDayView(BuildContext context) {
    final displayEmployees = _getDisplayEmployees();

    return Column(
      children: [
        // Header with employee names
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Time column header
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    'Zeit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Employee columns
              ...displayEmployees.map((employee) => Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        employee.position,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        // Time slots grid
        Expanded(
          child: _buildTimeGrid(context, displayEmployees, 1),
        ),
      ],
    );
  }

  Widget _buildWeekView(BuildContext context) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        // Header with days
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Time column header
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    'Zeit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Day columns
              ...weekDays.map((day) => Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isToday(day)
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(day.weekday),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _isToday(day)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      Text(
                        '${day.day}.${day.month}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isToday(day)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        // Time grid
        Expanded(
          child: _buildWeekTimeGrid(context, weekDays),
        ),
      ],
    );
  }

  Widget _buildMonthView(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    // Start from Monday of the week containing the first day
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));

    // End on Sunday of the week containing the last day
    final endDate = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));

    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map((dayName) =>
              Expanded(
                child: Center(
                  child: Text(
                    dayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: Column(
            children: List.generate(weeks, (weekIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final currentDate = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                    final isCurrentMonth = currentDate.month == selectedDate.month;
                    final dayShifts = shifts.where((shift) =>
                      shift.startTime.year == currentDate.year &&
                      shift.startTime.month == currentDate.month &&
                      shift.startTime.day == currentDate.day
                    ).toList();

                    return Expanded(
                      child: _buildMonthDayCell(context, currentDate, dayShifts, isCurrentMonth),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDayCell(BuildContext context, DateTime date, List<Shift> dayShifts, bool isCurrentMonth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 0.5,
        ),
        color: !isCurrentMonth
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : _isToday(date)
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
      ),
      child: InkWell(
        onTap: () => onTimeSlotTap(date),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day number
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: !isCurrentMonth
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
                      : _isToday(date)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
              ),
              // Shift indicators
              Expanded(
                child: ListView.builder(
                  itemCount: dayShifts.length > 3 ? 3 : dayShifts.length,
                  itemBuilder: (context, index) {
                    if (index == 2 && dayShifts.length > 3) {
                      return Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${dayShifts.length - 2}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }

                    final shift = dayShifts[index];
                    final employee = employees.firstWhere(
                      (e) => e.id == shift.employeeId,
                      orElse: () => Employee(
                        id: '',
                        firstName: 'Unknown',
                        lastName: '',
                        email: '',
                        phone: '',
                        position: '',
                        department: '',
                        hireDate: DateTime.now(),
                        hourlyRate: 0,
                        contractualHours: 0,
                        status: EmployeeStatus.active,
                      ),
                    );

                    return GestureDetector(
                      onTap: () => onShiftTap(shift),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getShiftTypeColor(shift.shiftType),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${shift.startTime.hour}:${shift.startTime.minute.toString().padLeft(2, '0')} ${employee.firstName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGrid(BuildContext context, List<Employee> displayEmployees, int days) {
    return ListView.builder(
      itemCount: 24, // 24 hours
      itemBuilder: (context, hourIndex) {
        return SizedBox(
          height: 60,
          child: Row(
            children: [
              // Time label
              SizedBox(
                width: 80,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${hourIndex.toString().padLeft(2, '0')}:00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Employee/day columns
              ...List.generate(displayEmployees.length, (employeeIndex) {
                final employee = displayEmployees[employeeIndex];
                final currentDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  hourIndex,
                );

                final hourShifts = shifts.where((shift) =>
                  shift.employeeId == employee.id &&
                  shift.startTime.hour <= hourIndex &&
                  shift.endTime.hour > hourIndex &&
                  shift.startTime.year == selectedDate.year &&
                  shift.startTime.month == selectedDate.month &&
                  shift.startTime.day == selectedDate.day
                ).toList();

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTimeSlotTap(currentDateTime),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        color: hourShifts.isNotEmpty
                            ? _getShiftTypeColor(hourShifts.first.shiftType).withOpacity(0.3)
                            : null,
                      ),
                      child: hourShifts.isNotEmpty
                          ? GestureDetector(
                              onTap: () => onShiftTap(hourShifts.first),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      hourShifts.first.shiftType.label,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${hourShifts.first.startTime.hour}:${hourShifts.first.startTime.minute.toString().padLeft(2, '0')} - ${hourShifts.first.endTime.hour}:${hourShifts.first.endTime.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekTimeGrid(BuildContext context, List<DateTime> weekDays) {
    return ListView.builder(
      itemCount: 24, // 24 hours
      itemBuilder: (context, hourIndex) {
        return SizedBox(
          height: 60,
          child: Row(
            children: [
              // Time label
              SizedBox(
                width: 80,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${hourIndex.toString().padLeft(2, '0')}:00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Day columns
              ...weekDays.map((day) {
                final currentDateTime = DateTime(day.year, day.month, day.day, hourIndex);

                final hourShifts = shifts.where((shift) =>
                  shift.startTime.year == day.year &&
                  shift.startTime.month == day.month &&
                  shift.startTime.day == day.day &&
                  shift.startTime.hour <= hourIndex &&
                  shift.endTime.hour > hourIndex
                ).toList();

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTimeSlotTap(currentDateTime),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        color: _isToday(day)
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
                            : null,
                      ),
                      child: Column(
                        children: hourShifts.map((shift) {
                          final employee = employees.firstWhere(
                            (e) => e.id == shift.employeeId,
                            orElse: () => Employee(
                              id: '',
                              firstName: 'Unknown',
                              lastName: '',
                              email: '',
                              phone: '',
                              position: '',
                              department: '',
                              hireDate: DateTime.now(),
                              hourlyRate: 0,
                              contractualHours: 0,
                              status: EmployeeStatus.active,
                            ),
                          );

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onShiftTap(shift),
                              child: Container(
                                margin: const EdgeInsets.all(1),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _getShiftTypeColor(shift.shiftType),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  employee.firstName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<Employee> _getDisplayEmployees() {
    if (selectedEmployeeIds.isEmpty) {
      return employees.where((employee) => employee.status == EmployeeStatus.active).toList();
    }
    return employees.where((employee) => selectedEmployeeIds.contains(employee.id)).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayName(int weekday) {
    const days = ['', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return days[weekday];
  }

  Color _getShiftTypeColor(ShiftType shiftType) {
    switch (shiftType) {
      case ShiftType.morning:
        return Colors.blue;
      case ShiftType.afternoon:
        return Colors.orange;
      case ShiftType.evening:
        return Colors.purple;
      case ShiftType.night:
        return Colors.indigo;
      case ShiftType.weekend:
        return Colors.green;
      case ShiftType.holiday:
        return Colors.red;
    }
  }
}