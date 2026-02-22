import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/team.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';

class TeamFormDialog extends ConsumerStatefulWidget {
  final Team? team;
  final Function(Team) onSave;

  const TeamFormDialog({
    super.key,
    this.team,
    required this.onSave,
  });

  @override
  ConsumerState<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends ConsumerState<TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  TeamStatus _selectedStatus = TeamStatus.active;
  List<String> _selectedMemberIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final team = widget.team!;
    _nameController.text = team.name;
    _descriptionController.text = team.description;
    _departmentController.text = team.department ?? '';
    _locationController.text = team.location ?? '';
    _budgetController.text = team.budget?.toStringAsFixed(2) ?? '';
    _selectedStatus = team.status;
    _selectedMemberIds = List.from(team.memberIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.corporate_fare,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.team == null ? 'Neues Team erstellen' : 'Team bearbeiten',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Team-Name',
                          hintText: 'z.B. Betreuungsteam A',
                          prefixIcon: Icon(Symbols.badge),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Team-Name ist erforderlich';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Beschreibung',
                          hintText: 'Kurze Beschreibung des Teams',
                          prefixIcon: Icon(Symbols.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Beschreibung ist erforderlich';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: const InputDecoration(
                                labelText: 'Abteilung',
                                hintText: 'z.B. Wohnen',
                                prefixIcon: Icon(Symbols.domain),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<TeamStatus>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Symbols.info),
                                border: OutlineInputBorder(),
                              ),
                              items: TeamStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(_getStatusLabel(status)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Standort',
                                hintText: 'z.B. Hauptgebäude',
                                prefixIcon: Icon(Symbols.location_on),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _budgetController,
                              decoration: const InputDecoration(
                                labelText: 'Budget (€)',
                                hintText: '0,00',
                                prefixIcon: Icon(Symbols.euro),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final budget = double.tryParse(value);
                                  if (budget == null || budget < 0) {
                                    return 'Ungültiger Budget-Betrag';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Team-Mitglieder',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      employeesAsync.when(
                        data: (employees) => _buildMemberSelection(employees),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Text(
                          'Fehler beim Laden der Mitarbeiter: $error',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _saveTeam,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.team == null ? 'Erstellen' : 'Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelection(List<Employee> employees) {
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();

    if (activeEmployees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Keine aktiven Mitarbeiter verfügbar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: activeEmployees.length,
        itemBuilder: (context, index) {
          final employee = activeEmployees[index];
          final isSelected = _selectedMemberIds.contains(employee.id);

          return CheckboxListTile(
            value: isSelected,
            title: Text(employee.fullName),
            subtitle: Text('${employee.position} • ${employee.department}'),
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedMemberIds.add(employee.id);
                } else {
                  _selectedMemberIds.remove(employee.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  String _getStatusLabel(TeamStatus status) {
    switch (status) {
      case TeamStatus.active:
        return 'Aktiv';
      case TeamStatus.inactive:
        return 'Inaktiv';
      case TeamStatus.onHold:
        return 'Pausiert';
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final team = Team(
        id: widget.team?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        status: _selectedStatus,
        memberIds: _selectedMemberIds,
        budget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
        createdAt: widget.team?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(team);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.team == null
                  ? 'Team erfolgreich erstellt'
                  : 'Team erfolgreich aktualisiert',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}