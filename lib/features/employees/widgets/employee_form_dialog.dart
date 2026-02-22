import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  final Function(Employee) onSave;

  const EmployeeFormDialog({
    super.key,
    this.employee,
    required this.onSave,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _employeeNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hoursPerWeekController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 25));
  DateTime _hireDate = DateTime.now();
  EmployeeStatus _status = EmployeeStatus.active;
  ContractType _contractType = ContractType.fullTime;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (_isEditing) {
      final employee = widget.employee!;
      _firstNameController.text = employee.firstName;
      _lastNameController.text = employee.lastName;
      _employeeNumberController.text = employee.employeeNumber;
      _emailController.text = employee.email;
      _phoneController.text = employee.phone ?? '';
      _positionController.text = employee.position;
      _departmentController.text = employee.department;
      _hoursPerWeekController.text = employee.hoursPerWeek.toString();
      _hourlyRateController.text = employee.hourlyRate.toString();
      _streetController.text = employee.address.street;
      _cityController.text = employee.address.city;
      _postalCodeController.text = employee.address.postalCode;
      _countryController.text = employee.address.country;
      _notesController.text = employee.notes ?? '';
      _dateOfBirth = employee.dateOfBirth;
      _hireDate = employee.hireDate;
      _status = employee.status;
      _contractType = employee.contractType;
    } else {
      _countryController.text = 'Deutschland';
      _employeeNumberController.text = _generateEmployeeNumber();
    }
  }

  String _generateEmployeeNumber() {
    final now = DateTime.now();
    return 'MA${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
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
                  _isEditing ? 'Mitarbeiter bearbeiten' : 'Neuer Mitarbeiter',
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
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 24),
                      _buildEmploymentSection(),
                      const SizedBox(height: 24),
                      _buildAddressSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saveEmployee,
                  child: Text(_isEditing ? 'Speichern' : 'Hinzufügen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Persönliche Daten',
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
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
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
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'E-Mail ist erforderlich';
                  }
                  if (!value!.contains('@')) {
                    return 'Ungültige E-Mail-Adresse';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context, true),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Geburtsdatum *',
              border: OutlineInputBorder(),
            ),
            child: Text(
              '${_dateOfBirth.day}.${_dateOfBirth.month}.${_dateOfBirth.year}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beschäftigungsdaten',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _employeeNumberController,
                decoration: const InputDecoration(
                  labelText: 'Mitarbeiternummer *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Mitarbeiternummer ist erforderlich';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Einstellungsdatum *',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_hireDate.day}.${_hireDate.month}.${_hireDate.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Position ist erforderlich';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Abteilung *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Abteilung ist erforderlich';
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
              child: DropdownButtonFormField<EmployeeStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: EmployeeStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusLabel(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<ContractType>(
                value: _contractType,
                decoration: const InputDecoration(
                  labelText: 'Vertragsart',
                  border: OutlineInputBorder(),
                ),
                items: ContractType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getContractTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _contractType = value!;
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
              child: TextFormField(
                controller: _hoursPerWeekController,
                decoration: const InputDecoration(
                  labelText: 'Stunden pro Woche *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Stunden pro Woche ist erforderlich';
                  }
                  final hours = int.tryParse(value!);
                  if (hours == null || hours <= 0 || hours > 60) {
                    return 'Gültige Stundenanzahl eingeben (1-60)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Stundenlohn (€) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Stundenlohn ist erforderlich';
                  }
                  final rate = double.tryParse(value!);
                  if (rate == null || rate <= 0) {
                    return 'Gültigen Stundenlohn eingeben';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(
            labelText: 'Straße und Hausnummer *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Straße ist erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'PLZ *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'PLZ ist erforderlich';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Stadt *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Stadt ist erforderlich';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Land *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Land ist erforderlich';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
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
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDateOfBirth) async {
    final initialDate = isDateOfBirth ? _dateOfBirth : _hireDate;
    final firstDate = isDateOfBirth
        ? DateTime(1950)
        : DateTime(2000);
    final lastDate = isDateOfBirth
        ? DateTime.now().subtract(const Duration(days: 365 * 16)) // Min 16 years old
        : DateTime.now().add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = date;
        } else {
          _hireDate = date;
        }
      });
    }
  }

  String _getStatusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Aktiv';
      case EmployeeStatus.inactive:
        return 'Inaktiv';
      case EmployeeStatus.onLeave:
        return 'Beurlaubt';
      case EmployeeStatus.terminated:
        return 'Gekündigt';
    }
  }

  String _getContractTypeLabel(ContractType type) {
    switch (type) {
      case ContractType.fullTime:
        return 'Vollzeit';
      case ContractType.partTime:
        return 'Teilzeit';
      case ContractType.freelance:
        return 'Freiberufler';
      case ContractType.intern:
        return 'Praktikant';
      case ContractType.temporary:
        return 'Befristet';
    }
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        street: _streetController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
      );

      final employee = Employee(
        id: _isEditing ? widget.employee!.id : '',
        employeeNumber: _employeeNumberController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        dateOfBirth: _dateOfBirth,
        hireDate: _hireDate,
        status: _status,
        contractType: _contractType,
        hoursPerWeek: double.parse(_hoursPerWeekController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        position: _positionController.text,
        department: _departmentController.text,
        address: address,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: _isEditing ? widget.employee!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(employee);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _employeeNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _hoursPerWeekController.dispose();
    _hourlyRateController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}