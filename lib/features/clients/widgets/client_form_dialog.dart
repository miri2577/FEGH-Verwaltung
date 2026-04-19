import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/client.dart';
import '../../../providers/team_provider.dart';
import '../../../providers/policy_provider.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../models/kostentraeger.dart';

class ClientFormDialog extends ConsumerStatefulWidget {
  final Client? client;
  final Function(Client) onSave;

  const ClientFormDialog({
    super.key,
    this.client,
    required this.onSave,
  });

  @override
  ConsumerState<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends ConsumerState<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _caseManagerController = TextEditingController();
  final _notesController = TextEditingController();

  // EH-Controller
  final _fachleistungsstundenController = TextEditingController();
  final _kalkulationsfaktorController = TextEditingController();
  final _stundensatzController = TextEditingController();

  DateTime? _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 30));
  ClientStatus _status = ClientStatus.active;
  ClientPriority _priority = ClientPriority.medium;
  List<ServiceType> _selectedServices = [];

  String? _responsibleEmployeeId;
  String? _deputyEmployeeId;
  String? _deputy2EmployeeId;
  final Set<String> _selectedEmployeeIds = <String>{};
  String? _teamId;

  // EH-State
  HilfeTyp? _hilfeTyp;
  FachleistungsIntervall? _fachleistungsIntervall;
  String? _kostenuebernahme;
  DateTime? _betreuungSeit;
  DateTime? _kostenuebernahmeVon;
  DateTime? _kostenuebernahmeBis;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  Widget _buildTeamSelection() {
    return Consumer(builder: (context, ref, _) {
      final teamsAsync = ref.watch(teamsProvider);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team-Zuordnung',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              teamsAsync.when(
                data: (teams) {
                  return DropdownButtonFormField<String?> (
                    value: _teamId != null && teams.any((t) => t.id == _teamId) ? _teamId : null,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Kein Team (nur Admin)')),
                      ...teams.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (val) => setState(() => _teamId = val),
                    decoration: const InputDecoration(labelText: 'Team'),
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, st) => Text('Teams konnten nicht geladen werden: $e'),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _initializeFields() {
    if (_isEditing) {
      final client = widget.client!;
      _firstNameController.text = client.firstName;
      _lastNameController.text = client.lastName;
      _emailController.text = client.email ?? '';
      _phoneController.text = client.phone ?? '';
      _addressController.text = client.address ?? '';
      _insuranceNumberController.text = client.insuranceNumber ?? '';
      _emergencyContactController.text = client.emergencyContact ?? '';
      _emergencyPhoneController.text = client.emergencyPhone ?? '';
      _caseManagerController.text = client.caseManager ?? '';
      _notesController.text = client.notes ?? '';
      _dateOfBirth = client.dateOfBirth;
      _status = client.status;
      _priority = client.priority;
      _selectedServices = List.from(client.services);
      _teamId = client.teamId;
      _responsibleEmployeeId = client.responsibleEmployeeId;
      _deputyEmployeeId = client.deputyEmployeeId;
      _deputy2EmployeeId = client.deputy2EmployeeId;
      _selectedEmployeeIds
        ..clear()
        ..addAll(client.assignedEmployees);

      // EH-Felder
      _fachleistungsstundenController.text = client.fachleistungsstunden?.toString() ?? '';
      _kostenuebernahme = client.kostenuebernahme;
      _kalkulationsfaktorController.text = client.kalkulationsfaktorOverride?.toString() ?? '';
      _stundensatzController.text = client.stundensatzOverride?.toString() ?? '';
      _hilfeTyp = client.hilfeTyp;
      _fachleistungsIntervall = client.fachleistungsIntervall;
      _betreuungSeit = client.betreuungSeit;
      _kostenuebernahmeVon = client.kostenuebernahmeVon;
      _kostenuebernahmeBis = client.kostenuebernahmeBis;
    } else {
      _selectedEmployeeIds.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEditing ? Symbols.edit : Symbols.person_add,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  _isEditing ? 'Klient bearbeiten' : 'Neuer Klient',
                  style: Theme.of(context).textTheme.headlineMedium,
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
                      _buildTeamSelection(),
                      const SizedBox(height: 16),
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 24),
                      _buildContactInfoSection(),
                      const SizedBox(height: 24),
                      _buildServiceInfoSection(),
                      const SizedBox(height: 24),
                      _buildEingliederungshilfeSection(),
                      const SizedBox(height: 24),
                      _buildAssignmentSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEingliederungshilfeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eingliederungshilfe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fachleistungsstundenController,
                    decoration: const InputDecoration(
                      labelText: 'FLS-Stunden (bewilligt)',
                      hintText: 'z.B. 120',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<FachleistungsIntervall?>(
                    value: _fachleistungsIntervall,
                    decoration: const InputDecoration(
                      labelText: 'Intervall',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Kein Intervall')),
                      DropdownMenuItem(
                          value: FachleistungsIntervall.woechentlich,
                          child: Text('Wöchentlich')),
                      DropdownMenuItem(
                          value: FachleistungsIntervall.monatlich,
                          child: Text('Monatlich')),
                      DropdownMenuItem(
                          value: FachleistungsIntervall.jaehrlich,
                          child: Text('Jährlich')),
                    ],
                    onChanged: (val) => setState(() => _fachleistungsIntervall = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<HilfeTyp?>(
                    value: _hilfeTyp,
                    decoration: const InputDecoration(
                      labelText: 'Hilfe-Typ',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Nicht festgelegt')),
                      DropdownMenuItem(
                          value: HilfeTyp.eingliederungshilfe,
                          child: Text('Eingliederungshilfe')),
                      DropdownMenuItem(
                          value: HilfeTyp.familienhilfe,
                          child: Text('Familienhilfe')),
                    ],
                    onChanged: (val) => setState(() => _hilfeTyp = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectOptionalDate(
                      context,
                      initial: _betreuungSeit,
                      onPicked: (d) => setState(() => _betreuungSeit = d),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Betreuung seit',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_betreuungSeit != null)
                              IconButton(
                                icon: const Icon(Symbols.close, size: 18),
                                onPressed: () => setState(() => _betreuungSeit = null),
                              ),
                            const Icon(Symbols.calendar_today),
                          ],
                        ),
                      ),
                      child: Text(
                        _betreuungSeit != null
                            ? '${_betreuungSeit!.day.toString().padLeft(2, '0')}.${_betreuungSeit!.month.toString().padLeft(2, '0')}.${_betreuungSeit!.year}'
                            : 'Nicht festgelegt',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final options = Kostentraeger.getFuerHilfeTyp(_hilfeTyp);
              // Wenn aktueller Wert nicht in gefilterter Liste, trotzdem anzeigen
              final effectiveValue = _kostenuebernahme != null && options.contains(_kostenuebernahme)
                  ? _kostenuebernahme
                  : (_kostenuebernahme != null ? _kostenuebernahme : null);
              return DropdownButtonFormField<String?>(
                value: effectiveValue,
                decoration: const InputDecoration(
                  labelText: 'Kostenträger',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Nicht festgelegt')),
                  if (_kostenuebernahme != null && !options.contains(_kostenuebernahme))
                    DropdownMenuItem<String?>(value: _kostenuebernahme, child: Text('$_kostenuebernahme (benutzerdefiniert)')),
                  ...options.map((k) => DropdownMenuItem<String?>(value: k, child: Text(k))),
                ],
                onChanged: (val) => setState(() => _kostenuebernahme = val),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectOptionalDate(
                      context,
                      initial: _kostenuebernahmeVon,
                      onPicked: (d) => setState(() => _kostenuebernahmeVon = d),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kostenübernahme von',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_kostenuebernahmeVon != null)
                              IconButton(
                                icon: const Icon(Symbols.close, size: 18),
                                onPressed: () => setState(() => _kostenuebernahmeVon = null),
                              ),
                            const Icon(Symbols.calendar_today),
                          ],
                        ),
                      ),
                      child: Text(
                        _kostenuebernahmeVon != null
                            ? '${_kostenuebernahmeVon!.day.toString().padLeft(2, '0')}.${_kostenuebernahmeVon!.month.toString().padLeft(2, '0')}.${_kostenuebernahmeVon!.year}'
                            : 'Nicht festgelegt',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectOptionalDate(
                      context,
                      initial: _kostenuebernahmeBis,
                      onPicked: (d) => setState(() => _kostenuebernahmeBis = d),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kostenübernahme bis',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_kostenuebernahmeBis != null)
                              IconButton(
                                icon: const Icon(Symbols.close, size: 18),
                                onPressed: () => setState(() => _kostenuebernahmeBis = null),
                              ),
                            const Icon(Symbols.calendar_today),
                          ],
                        ),
                      ),
                      child: Text(
                        _kostenuebernahmeBis != null
                            ? '${_kostenuebernahmeBis!.day.toString().padLeft(2, '0')}.${_kostenuebernahmeBis!.month.toString().padLeft(2, '0')}.${_kostenuebernahmeBis!.year}'
                            : 'Nicht festgelegt',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Kalkulation (optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kalkulationsfaktorController,
                    decoration: const InputDecoration(
                      labelText: 'Kalkulationsfaktor',
                      hintText: 'z.B. 1.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stundensatzController,
                    decoration: const InputDecoration(
                      labelText: 'Stundensatz (EUR)',
                      hintText: 'z.B. 55.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSection() {
    final employeesAsync = ref.watch(activeEmployeesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mitarbeiterzuordnung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            employeesAsync.when(
              data: (employees) {
                final list = employees;

                List<Employee> optionsFor(String? excludeA, [String? excludeB]) {
                  return list.where((e) => e.id != excludeA && e.id != excludeB).toList();
                }

                String displayName(Employee e) => e.fullName;

                Widget dropdownField({
                  required String label,
                  required String? value,
                  required List<Employee> options,
                  required void Function(String?) onChanged,
                }) {
                  return DropdownButtonFormField<String?>(
                    value: value != null && options.any((e) => e.id == value) ? value : null,
                    decoration: InputDecoration(labelText: label),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Keine Auswahl')),
                      ...options.map((e) => DropdownMenuItem<String?>(
                            value: e.id,
                            child: Text(displayName(e)),
                          )),
                    ],
                    onChanged: onChanged,
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: dropdownField(
                            label: 'Verantwortlicher Mitarbeiter',
                            value: _responsibleEmployeeId,
                            options: optionsFor(null),
                            onChanged: (val) {
                              setState(() {
                                _responsibleEmployeeId = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: dropdownField(
                            label: 'Vertreter',
                            value: _deputyEmployeeId,
                            options: optionsFor(_responsibleEmployeeId),
                            onChanged: (val) {
                              setState(() {
                                _deputyEmployeeId = val;
                                if (_deputyEmployeeId == _responsibleEmployeeId) {
                                  _deputyEmployeeId = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: dropdownField(
                            label: 'Vertreter 2',
                            value: _deputy2EmployeeId,
                            options: optionsFor(_responsibleEmployeeId, _deputyEmployeeId),
                            onChanged: (val) {
                              setState(() {
                                _deputy2EmployeeId = val;
                                if (_deputy2EmployeeId == _responsibleEmployeeId ||
                                    _deputy2EmployeeId == _deputyEmployeeId) {
                                  _deputy2EmployeeId = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Zugewiesene Mitarbeiter',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final emp = list[index];
                        final checked = _selectedEmployeeIds.contains(emp.id);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(displayName(emp)),
                          value: checked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedEmployeeIds.add(emp.id);
                              } else {
                                _selectedEmployeeIds.remove(emp.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text(
                'Mitarbeiter konnten nicht geladen werden.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Persönliche Informationen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vorname *',
                      hintText: 'Max',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vorname ist erforderlich';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nachname *',
                      hintText: 'Mustermann',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Nachname ist erforderlich';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum *',
                        suffixIcon: Icon(Symbols.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}.${_dateOfBirth!.month}.${_dateOfBirth!.year}'
                            : 'Nicht angegeben',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _insuranceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Versicherungsnummer',
                      hintText: 'M123456789',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ClientStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: ClientStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusLabel(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ClientPriority>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorität',
                    ),
                    items: ClientPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(_getPriorityLabel(priority)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _priority = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontaktinformationen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      hintText: 'max.mustermann@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      hintText: '+49 30 123456789',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                hintText: 'Musterstraße 1, 10115 Berlin',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emergencyContactController,
                    decoration: const InputDecoration(
                      labelText: 'Notfallkontakt',
                      hintText: 'Anna Mustermann',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Notfall-Telefon',
                      hintText: '+49 30 987654321',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caseManagerController,
              decoration: const InputDecoration(
                labelText: 'Fallmanager',
                hintText: 'Sarah Weber',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ServiceType.values.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(_getServiceLabel(service)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notizen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Zusätzliche Informationen',
                hintText: 'Regelmäßige Termine, sehr kooperativ...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        const SizedBox(width: 16),
        FilledButton(
          onPressed: _saveClient,
          child: Text(_isEditing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _selectOptionalDate(
    BuildContext context, {
    required DateTime? initial,
    required void Function(DateTime) onPicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _saveClient() {
    // Simple policy check: disallow save if no permission
    try {
      final policy = ref.read(policyProvider);
      if (_isEditing) {
        if (!policy.canEditClient(teamId: _teamId)) return;
      } else {
        if (!policy.canCreateClient(teamId: _teamId)) return;
      }
    } catch (_) {}
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      // Rollen sicher in assignedEmployees eintragen
      final assigned = <String>{
        ..._selectedEmployeeIds,
        if (_responsibleEmployeeId != null) _responsibleEmployeeId!,
        if (_deputyEmployeeId != null) _deputyEmployeeId!,
        if (_deputy2EmployeeId != null) _deputy2EmployeeId!,
      };

      // EH-Felder parsen
      final flsText = _fachleistungsstundenController.text.trim();
      final fls = flsText.isNotEmpty ? int.tryParse(flsText) : null;
      final kalkText = _kalkulationsfaktorController.text.trim();
      final kalk = kalkText.isNotEmpty ? double.tryParse(kalkText) : null;
      final satzText = _stundensatzController.text.trim();
      final satz = satzText.isNotEmpty ? double.tryParse(satzText) : null;
      final client = Client(
        id: widget.client?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        teamId: _teamId,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        dateOfBirth: _dateOfBirth,
        status: _status,
        priority: _priority,
        services: _selectedServices,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        caseManager: _caseManagerController.text.trim().isEmpty ? null : _caseManagerController.text.trim(),
        createdAt: widget.client?.createdAt ?? now,
        updatedAt: now,
        insuranceNumber: _insuranceNumberController.text.trim().isEmpty ? null : _insuranceNumberController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        assignedEmployees: assigned.toList(),
        responsibleEmployeeId: _responsibleEmployeeId,
        deputyEmployeeId: _deputyEmployeeId,
        deputy2EmployeeId: _deputy2EmployeeId,
        // EH-Felder
        fachleistungsstunden: fls,
        fachleistungsIntervall: _fachleistungsIntervall,
        hilfeTyp: _hilfeTyp,
        kostenuebernahme: _kostenuebernahme,
        kostenuebernahmeVon: _kostenuebernahmeVon,
        kostenuebernahmeBis: _kostenuebernahmeBis,
        betreuungSeit: _betreuungSeit,
        kalkulationsfaktorOverride: kalk,
        stundensatzOverride: satz,
        verbrauchteStunden: widget.client?.verbrauchteStunden ?? 0.0,
      );

      widget.onSave(client);
      Navigator.of(context).pop();
    }
  }

  String _getStatusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.active:
        return 'Aktiv';
      case ClientStatus.inactive:
        return 'Inaktiv';
      case ClientStatus.pending:
        return 'Anstehend';
      case ClientStatus.archived:
        return 'Archiviert';
    }
  }

  String _getPriorityLabel(ClientPriority priority) {
    switch (priority) {
      case ClientPriority.low:
        return 'Niedrig';
      case ClientPriority.medium:
        return 'Mittel';
      case ClientPriority.high:
        return 'Hoch';
      case ClientPriority.urgent:
        return 'Dringend';
    }
  }

  String _getServiceLabel(ServiceType service) {
    switch (service) {
      case ServiceType.ambulant:
        return 'Ambulant';
      case ServiceType.stationaer:
        return 'Stationär';
      case ServiceType.beratung:
        return 'Beratung';
      case ServiceType.begleitung:
        return 'Begleitung';
      case ServiceType.wohnen:
        return 'Wohnen';
      case ServiceType.arbeit:
        return 'Arbeit';
      case ServiceType.freizeit:
        return 'Freizeit';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _insuranceNumberController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _caseManagerController.dispose();
    _notesController.dispose();
    _fachleistungsstundenController.dispose();
    _kalkulationsfaktorController.dispose();
    _stundensatzController.dispose();
    super.dispose();
  }
}
