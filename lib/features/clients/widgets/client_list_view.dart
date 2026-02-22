import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/client.dart';
import '../../../providers/client_provider.dart';
import 'client_card.dart';
import 'client_form_dialog.dart';
import '../../../providers/policy_provider.dart';

class ClientListView extends ConsumerStatefulWidget {
  final List<Client> clients;
  final bool isTableView;

  const ClientListView({super.key, required this.clients, this.isTableView = false});

  @override
  ConsumerState<ClientListView> createState() => _ClientListViewState();
}

class _ClientListViewState extends ConsumerState<ClientListView> {
  String _searchQuery = '';
  ClientStatus? _statusFilter;
  ClientPriority? _priorityFilter;
  ServiceType? _serviceFilter;

  @override
  Widget build(BuildContext context) {
    final filteredClients = _filterClients(widget.clients);

    return Column(
      children: [
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child: filteredClients.isEmpty
              ? _buildNoResultsState()
              : widget.isTableView
                  ? _buildClientTable(filteredClients)
                  : _buildClientGrid(filteredClients),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Klienten suchen...',
                  prefixIcon: const Icon(Symbols.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<ClientStatus?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Status')),
                ...ClientStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusLabel(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<ClientPriority?>(
              value: _priorityFilter,
              hint: const Text('Priorität'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Prioritäten')),
                ...ClientPriority.values.map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(_getPriorityLabel(priority)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _priorityFilter = value;
                });
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<ServiceType?>(
              value: _serviceFilter,
              hint: const Text('Service'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Services')),
                ...ServiceType.values.map(
                  (service) => DropdownMenuItem(
                    value: service,
                    child: Text(_getServiceLabel(service)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _serviceFilter = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientGrid(List<Client> clients) {
    final policy = ref.read(policyProvider);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        final canEdit = policy.canEditClient(teamId: client.teamId);
        final canDelete = policy.canDeleteClient(teamId: client.teamId);
        final canArchive = policy.canEditClient(teamId: client.teamId);
        return ClientCard(
          client: client,
          onTap: () => _showClientDetails(client),
          onEdit: canEdit ? () => _showEditClientDialog(client) : null,
          onDelete: canDelete ? () => _showDeleteConfirmation(client) : null,
          onArchive: canArchive ? () => _showArchiveConfirmation(client) : null,
          canEdit: canEdit,
          canDelete: canDelete,
          canArchive: canArchive,
        );
      },
    );
  }

  Widget _buildClientTable(List<Client> clients) {
    final policy = ref.read(policyProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Priorität')),
            DataColumn(label: Text('Hilfe-Typ')),
            DataColumn(label: Text('FLS')),
            DataColumn(label: Text('Kostenträger')),
            DataColumn(label: Text('Aktionen')),
          ],
          rows: clients.map((client) {
            final canEdit = policy.canEditClient(teamId: client.teamId);
            final canDelete = policy.canDeleteClient(teamId: client.teamId);
            return DataRow(
              cells: [
                DataCell(Text(client.fullName), onTap: () => _showClientDetails(client)),
                DataCell(Text(client.statusDisplayName)),
                DataCell(Text(client.priorityDisplayName)),
                DataCell(Text(client.hilfeTypDisplay)),
                DataCell(Text(client.fachleistungsstunden != null ? '${client.fachleistungsstunden} Std.' : '-')),
                DataCell(Text(client.kostenuebernahme ?? '-')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Symbols.edit, size: 18),
                        onPressed: () => _showEditClientDialog(client),
                        tooltip: 'Bearbeiten',
                        visualDensity: VisualDensity.compact,
                      ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Symbols.delete, size: 18),
                        onPressed: () => _showDeleteConfirmation(client),
                        tooltip: 'Löschen',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.person_search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Klienten gefunden',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Versuchen Sie andere Suchkriterien.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Client> _filterClients(List<Client> clients) {
    return clients.where((client) {
      final matchesSearch = _searchQuery.isEmpty ||
          client.fullName.toLowerCase().contains(_searchQuery) ||
          (client.email?.toLowerCase().contains(_searchQuery) ?? false) ||
          (client.insuranceNumber?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesStatus = _statusFilter == null || client.status == _statusFilter;

      final matchesPriority = _priorityFilter == null || client.priority == _priorityFilter;

      final matchesService = _serviceFilter == null || client.services.contains(_serviceFilter);

      return matchesSearch && matchesStatus && matchesPriority && matchesService;
    }).toList();
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

  void _showClientDetails(Client client) {
    final policy = ref.read(policyProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.fullName),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${client.id}'),
              if (client.email != null) Text('E-Mail: ${client.email}'),
              if (client.phone != null) Text('Telefon: ${client.phone}'),
              if (client.address != null) Text('Adresse: ${client.address}'),
              Text('Geburtsdatum: ${client.dateOfBirth.toLocal().toString().split(' ')[0]}'),
              Text('Alter: ${client.age} Jahre'),
              Text('Status: ${client.statusDisplayName}'),
              Text('Priorität: ${client.priorityDisplayName}'),
              Text('Services: ${client.serviceDisplayNames.join(', ')}'),
              if (client.caseManager != null) Text('Fallmanager: ${client.caseManager}'),
              if (client.insuranceNumber != null) Text('Versicherungsnummer: ${client.insuranceNumber}'),
              if (client.emergencyContact != null) Text('Notfallkontakt: ${client.emergencyContact}'),
              if (client.emergencyPhone != null) Text('Notfall-Telefon: ${client.emergencyPhone}'),
              if (client.notes != null) Text('Notizen: ${client.notes}'),
              Text('Zugewiesene Mitarbeiter: ${client.assignedEmployees.length}'),
              if (client.hilfeTyp != null || client.fachleistungsstunden != null) ...[
                const Divider(),
                Text('Eingliederungshilfe', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (client.hilfeTyp != null) Text('Hilfe-Typ: ${client.hilfeTypDisplay}'),
                if (client.fachleistungsstunden != null)
                  Text('FLS: ${client.fachleistungsstunden} Std. / ${client.fachleistungsIntervallDisplay}'),
                if (client.verbrauchteStunden > 0)
                  Text('Verbraucht: ${client.verbrauchteStunden.toStringAsFixed(1)} Std. (${client.stundenverbrauchProzent.toStringAsFixed(0)}%)'),
                if (client.kostenuebernahme != null) Text('Kostenträger: ${client.kostenuebernahme}'),
                if (client.kostenuebernahmeVon != null)
                  Text('Kostenübernahme: ${client.kostenuebernahmeVon!.day.toString().padLeft(2, '0')}.${client.kostenuebernahmeVon!.month.toString().padLeft(2, '0')}.${client.kostenuebernahmeVon!.year}'
                      '${client.kostenuebernahmeBis != null ? ' - ${client.kostenuebernahmeBis!.day.toString().padLeft(2, '0')}.${client.kostenuebernahmeBis!.month.toString().padLeft(2, '0')}.${client.kostenuebernahmeBis!.year}' : ''}'),
                if (client.betreuungSeit != null)
                  Text('Betreuung seit: ${client.betreuungSeit!.day.toString().padLeft(2, '0')}.${client.betreuungSeit!.month.toString().padLeft(2, '0')}.${client.betreuungSeit!.year}'),
                if (client.kalkulationsfaktorOverride != null) Text('Kalkulationsfaktor: ${client.kalkulationsfaktorOverride}'),
                if (client.stundensatzOverride != null) Text('Stundensatz: ${client.stundensatzOverride!.toStringAsFixed(2)} EUR'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          if (policy.canEditClient(teamId: client.teamId))
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditClientDialog(client);
              },
              child: const Text('Bearbeiten'),
            ),
        ],
      ),
    );
  }

  void _showEditClientDialog(Client client) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(
        client: client,
        onSave: (updatedClient) async {
          await ref.read(clientProvider.notifier).updateClient(updatedClient);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klient löschen'),
        content: Text(
          'Möchten Sie den Klienten "${client.fullName}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
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
              await ref.read(clientProvider.notifier).deleteClient(client.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klient archivieren'),
        content: Text(
          'Möchten Sie den Klienten "${client.fullName}" archivieren? '
          'Archivierte Klienten können später wieder aktiviert werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(clientProvider.notifier).archiveClient(client.id);
            },
            child: const Text('Archivieren'),
          ),
        ],
      ),
    );
  }
}
