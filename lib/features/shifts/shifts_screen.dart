import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/shift.dart';
import '../../providers/shift_provider.dart';
import 'widgets/shift_card.dart';
import 'widgets/shift_form_dialog.dart';

class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsyncValue = ref.watch(shiftsProvider);
    final shiftCount = ref.watch(shiftCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.schedule,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Schichtplanung',
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
                    '$shiftCount Schichten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _refreshShifts(ref),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showAddShiftDialog(),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Neue Schicht'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Heute'),
                Tab(text: 'Kommend'),
                Tab(text: 'Aktiv'),
                Tab(text: 'Alle'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodaysShifts(),
                  _buildUpcomingShifts(),
                  _buildActiveShifts(),
                  _buildAllShifts(shiftsAsyncValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final todaysShifts = ref.watch(todaysShiftsProvider);
        return todaysShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine Schichten heute', 'Alle Schichten für heute sind abgeschlossen oder es sind keine geplant.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildUpcomingShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final upcomingShifts = ref.watch(upcomingShiftsProvider);
        return upcomingShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine kommenden Schichten', 'Es sind keine zukünftigen Schichten geplant.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildActiveShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final activeShifts = ref.watch(activeShiftsProvider);
        return activeShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine aktiven Schichten', 'Derzeit sind keine Schichten aktiv.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildAllShifts(AsyncValue<List<Shift>> shiftsAsyncValue) {
    return shiftsAsyncValue.when(
      data: (shifts) => shifts.isEmpty
          ? _buildEmptyState('Keine Schichten vorhanden', 'Erstellen Sie die erste Schicht, um zu beginnen.')
          : _buildShiftsList(shifts),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildShiftsList(List<Shift> shifts) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        return ShiftCard(
          shift: shift,
          onTap: () => _showShiftDetails(shift),
          onEdit: () => _showEditShiftDialog(shift),
          onDelete: () => _showDeleteConfirmation(shift),
          onStart: () => _startShift(shift.id),
          onEnd: () => _endShift(shift.id),
          onCancel: () => _cancelShift(shift.id),
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
            Symbols.schedule,
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
            'Fehler beim Laden der Schichten',
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
            onPressed: () => _refreshShifts(ref),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshShifts(WidgetRef ref) {
    ref.read(shiftsProvider.notifier).refresh();
  }

  void _showAddShiftDialog() {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        onSave: (shift) async {
          await ref.read(shiftsProvider.notifier).addShift(shift);
        },
      ),
    );
  }

  void _showEditShiftDialog(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        shift: shift,
        onSave: (updatedShift) async {
          await ref.read(shiftsProvider.notifier).updateShift(updatedShift);
        },
      ),
    );
  }

  void _showShiftDetails(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schichtdetails'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mitarbeiter ID: ${shift.employeeId}'),
              Text('Beginn: ${shift.startTime}'),
              Text('Ende: ${shift.endTime}'),
              Text('Status: ${shift.status.toString().split('.').last}'),
              Text('Typ: ${shift.type.toString().split('.').last}'),
              if (shift.location != null) Text('Standort: ${shift.location}'),
              if (shift.description != null) Text('Beschreibung: ${shift.description}'),
              Text('Stundenlohn: €${shift.hourlyRate.toStringAsFixed(2)}'),
              Text('Geplante Stunden: ${shift.scheduledHours.toStringAsFixed(1)}h'),
              if (shift.actualHours != null)
                Text('Tatsächliche Stunden: ${shift.actualHours!.toStringAsFixed(1)}h'),
              if (shift.notes != null) Text('Notizen: ${shift.notes}'),
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

  void _showDeleteConfirmation(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schicht löschen'),
        content: Text('Möchten Sie diese Schicht wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
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
              await ref.read(shiftsProvider.notifier).deleteShift(shift.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _startShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).startShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht gestartet'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _endShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).endShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht beendet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _cancelShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).cancelShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht abgesagt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}