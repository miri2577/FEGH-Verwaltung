import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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

  CalendarView _getCalendarView() {
    switch (viewMode) {
      case 'day':
        return CalendarView.day;
      case 'week':
        return CalendarView.week;
      case 'month':
        return CalendarView.month;
      default:
        return CalendarView.week;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: _getCalendarView(),
      initialDisplayDate: selectedDate,
      dataSource: _ShiftCalendarDataSource(shifts, employees),
      firstDayOfWeek: 1, // Monday
      showNavigationArrow: false,
      headerHeight: 0, // Header handled by parent toolbar
      viewHeaderStyle: ViewHeaderStyle(
        dayTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dateTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      todayHighlightColor: Theme.of(context).colorScheme.primary,
      cellBorderColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 6,
        endHour: 23,
        timeIntervalHeight: 60,
        timeFormat: 'HH:mm',
      ),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
        agendaViewHeight: 150,
      ),
      appointmentTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final appointment = details.appointments!.first as Appointment;
          final shift = shifts.firstWhere(
            (s) => s.id == appointment.id?.toString(),
            orElse: () => shifts.first,
          );
          onShiftTap(shift);
        } else if (details.date != null) {
          onTimeSlotTap(details.date!);
        }
      },
      onAppointmentResizeEnd: (details) {
        final appointment = details.appointment;
        final shift = shifts.firstWhere(
          (s) => s.id == appointment.id?.toString(),
          orElse: () => shifts.first,
        );
        onShiftDrag(shift, details.startTime!);
      },
      allowDragAndDrop: true,
      onDragEnd: (details) {
        final appointment = details.appointment as Appointment;
        final shift = shifts.firstWhere(
          (s) => s.id == appointment.id?.toString(),
          orElse: () => shifts.first,
        );
        onShiftDrag(shift, details.droppingTime!);
      },
    );
  }
}

class _ShiftCalendarDataSource extends CalendarDataSource {
  final List<Shift> shifts;
  final List<Employee> employees;

  _ShiftCalendarDataSource(this.shifts, this.employees) {
    appointments = shifts.map((shift) {
      final employee = employees.where((e) => e.id == shift.employeeId).firstOrNull;
      final empName = employee?.fullName ?? 'Unbekannt';

      return Appointment(
        id: shift.id,
        startTime: shift.startTime,
        endTime: shift.endTime,
        subject: '$empName – ${_getTypeLabel(shift.type)}',
        color: _getTypeColor(shift.type),
        notes: shift.notes,
        location: shift.location,
      );
    }).toList();
  }

  Color _getTypeColor(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return Colors.blue;
      case ShiftType.overtime:
        return Colors.red;
      case ShiftType.holiday:
        return Colors.green;
      case ShiftType.night:
        return Colors.indigo;
      case ShiftType.weekend:
        return Colors.orange;
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
        return 'Nacht';
      case ShiftType.weekend:
        return 'Wochenende';
    }
  }
}
