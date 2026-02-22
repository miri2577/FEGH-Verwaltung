import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import 'widgets/client_list_view.dart';
import '../../providers/policy_provider.dart';
import 'widgets/client_form_dialog.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isTableView = false;

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
    final clients = ref.watch(clientProvider);
    final clientNotifier = ref.watch(clientProvider.notifier);

    final activeClients = clientNotifier.activeClients;
    final pendingClients = clientNotifier.pendingClients;
    final urgentClients = clientNotifier.urgentClients;
    final archivedClients = clientNotifier.archivedClients;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Symbols.people,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Klientenverwaltung',
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
                    '${activeClients.length} aktiv',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (urgentClients.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${urgentClients.length} dringend',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Symbols.grid_view, size: 18)),
                    ButtonSegment(value: true, icon: Icon(Symbols.table_rows, size: 18)),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isTableView = value.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                // Search Field
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    hintText: 'Klienten durchsuchen...',
                    leading: const Icon(Symbols.search),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _refreshClients(),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: ref.read(policyProvider).canCreateClient()
                      ? () => _showAddClientDialog()
                      : null,
                  icon: const Icon(Symbols.person_add, size: 18),
                  label: const Text('Neuer Klient'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'Alle (${clients.length})',
                ),
                Tab(
                  text: 'Aktiv (${activeClients.length})',
                ),
                Tab(
                  text: 'Anstehend (${pendingClients.length})',
                ),
                Tab(
                  text: 'Archiviert (${archivedClients.length})',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildClientsList(_filterClients(clients)),
                  _buildClientsList(_filterClients(activeClients)),
                  _buildClientsList(_filterClients(pendingClients)),
                  _buildClientsList(_filterClients(archivedClients)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Client> _filterClients(List<Client> clients) {
    if (_searchQuery.isEmpty) return clients;
    return clientNotifier.searchClients(_searchQuery);
  }

  Widget _buildClientsList(List<Client> clients) {
    if (clients.isEmpty) {
      return _buildEmptyState();
    }
    return ClientListView(clients: clients, isTableView: _isTableView);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.person_off,
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
            _searchQuery.isEmpty
                ? 'Fügen Sie den ersten Klienten hinzu, um zu beginnen.'
                : 'Keine Klienten entsprechen Ihrer Suche.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshClients() {
    // Trigger a rebuild to refresh the data
    ref.invalidate(clientProvider);
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(
        onSave: (client) async {
          await ref.read(clientProvider.notifier).addClient(client);
        },
      ),
    );
  }

  ClientNotifier get clientNotifier => ref.read(clientProvider.notifier);
}
