import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/policy_provider.dart';
import 'widgets/client_documents_card.dart';
import 'widgets/client_form_dialog.dart';
import '../medication/medication_plan_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientProfileScreen({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
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
    final clients = ref.watch(clientProvider);
    final client = clients.where((c) => c.id == widget.clientId).firstOrNull;

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Klient nicht gefunden')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.person_off, size: 64),
              SizedBox(height: 16),
              Text('Klient wurde nicht gefunden.'),
            ],
          ),
        ),
      );
    }

    final policy = ref.read(policyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(client.fullName),
        actions: [
          if (policy.canEditClient(teamId: client.teamId))
            IconButton(
              onPressed: () => _showEditDialog(client),
              icon: const Icon(Symbols.edit),
              tooltip: 'Bearbeiten',
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MedicationPlanScreen(
                    clientId: client.id,
                    clientName: client.fullName,
                  ),
                ),
              );
            },
            icon: const Icon(Symbols.medication),
            tooltip: 'Medikationsplan',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Symbols.download),
                    SizedBox(width: 8),
                    Text('Profil exportieren'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Symbols.print),
                    SizedBox(width: 8),
                    Text('Profil drucken'),
                  ],
                ),
              ),
              if (client.status != ClientStatus.archived)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Symbols.archive, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Archivieren'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Symbols.unarchive, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Aktivieren'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) => _handleMenuAction(value, client),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Symbols.person), text: 'Profil'),
            Tab(icon: Icon(Symbols.folder), text: 'Dokumente'),
            Tab(icon: Icon(Symbols.accessibility_new), text: 'Teilhabe'),
            Tab(icon: Icon(Symbols.dashboard), text: '\u00dcbersicht'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(client),
          _buildDocumentsTab(client),
          _buildTeilhabeTab(client),
          _buildUebersichtTab(client),
        ],
      ),
    );
  }

  // ── Tab 1: Profil ──

  Widget _buildProfileTab(Client client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoCard(client),
          const SizedBox(height: 24),
          _buildPersonalDataCard(client),
          const SizedBox(height: 24),
          _buildEingliederungshilfeCard(client),
          const SizedBox(height: 24),
          _buildZuweisungenCard(client),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Client client) {
    final initials = '${client.firstName.isNotEmpty ? client.firstName[0] : ''}${client.lastName.isNotEmpty ? client.lastName[0] : ''}'.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    client.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${client.age} Jahre',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildStatusBadge(client),
                      _buildPriorityBadge(client),
                      ...client.serviceDisplayNames.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Client client) {
    Color color;
    switch (client.status) {
      case ClientStatus.active:
        color = Colors.green;
        break;
      case ClientStatus.inactive:
        color = Colors.grey;
        break;
      case ClientStatus.pending:
        color = Colors.orange;
        break;
      case ClientStatus.archived:
        color = Colors.brown;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        client.statusDisplayName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPriorityBadge(Client client) {
    Color color;
    switch (client.priority) {
      case ClientPriority.low:
        color = Colors.blue;
        break;
      case ClientPriority.medium:
        color = Colors.teal;
        break;
      case ClientPriority.high:
        color = Colors.orange;
        break;
      case ClientPriority.urgent:
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        client.priorityDisplayName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPersonalDataCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.badge, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Pers\u00f6nliche Daten',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Geburtsdatum', _formatDate(client.dateOfBirth)),
            _buildInfoRow('E-Mail', client.email ?? 'Nicht angegeben'),
            _buildInfoRow('Telefon', client.phone ?? 'Nicht angegeben'),
            _buildInfoRow('Adresse', client.address ?? 'Nicht angegeben'),
            _buildInfoRow('Versicherungsnr.', client.insuranceNumber ?? 'Nicht angegeben'),
            _buildInfoRow('Notfallkontakt', client.emergencyContact ?? 'Nicht angegeben'),
            if (client.emergencyPhone != null)
              _buildInfoRow('Notfall-Telefon', client.emergencyPhone!),
          ],
        ),
      ),
    );
  }

  Widget _buildEingliederungshilfeCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.health_and_safety, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Eingliederungshilfe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (client.hilfeTyp != null)
              _buildInfoRow('Hilfe-Typ', client.hilfeTypDisplay),
            if (client.fachleistungsstunden != null) ...[
              _buildInfoRow('FLS', '${client.fachleistungsstunden} Std. / ${client.fachleistungsIntervallDisplay}'),
              const SizedBox(height: 12),
              _buildFlsProgressBar(client),
              const SizedBox(height: 12),
            ],
            if (client.kostenuebernahme != null)
              _buildInfoRow('Kostentr\u00e4ger', client.kostenuebernahme!),
            if (client.kostenuebernahmeVon != null)
              _buildInfoRow(
                'Kosten\u00fcbernahme',
                '${_formatDate(client.kostenuebernahmeVon!)}'
                '${client.kostenuebernahmeBis != null ? ' - ${_formatDate(client.kostenuebernahmeBis!)}' : ''}',
              ),
            if (client.betreuungSeit != null)
              _buildInfoRow('Betreuung seit', _formatDate(client.betreuungSeit!)),
            if (client.kalkulationsfaktorOverride != null)
              _buildInfoRow('Kalkulationsfaktor', '${client.kalkulationsfaktorOverride}'),
            if (client.stundensatzOverride != null)
              _buildInfoRow('Stundensatz', '${client.stundensatzOverride!.toStringAsFixed(2)} EUR'),
          ],
        ),
      ),
    );
  }

  Widget _buildFlsProgressBar(Client client) {
    final prozent = client.stundenverbrauchProzent.clamp(0.0, 100.0);
    final farbe = prozent > 90 ? Colors.red : prozent > 70 ? Colors.orange : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verbraucht: ${client.verbrauchteStunden.toStringAsFixed(1)} Std.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Verf\u00fcgbar: ${client.verfuegbareStunden.toStringAsFixed(1)} Std.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: prozent / 100,
            minHeight: 10,
            backgroundColor: farbe.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(farbe),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${prozent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: farbe,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZuweisungenCard(Client client) {
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.valueOrNull ?? [];

    String employeeName(String? id) {
      if (id == null) return 'Nicht zugewiesen';
      final emp = employees.where((e) => e.id == id).firstOrNull;
      return emp?.fullName ?? id;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.group, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Zuweisungen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Zust\u00e4ndiger MA', employeeName(client.responsibleEmployeeId)),
            _buildInfoRow('Vertretung 1', employeeName(client.deputyEmployeeId)),
            _buildInfoRow('Vertretung 2', employeeName(client.deputy2EmployeeId)),
            if (client.caseManager != null)
              _buildInfoRow('Case Manager', client.caseManager!),
            if (client.assignedEmployees.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Alle zugewiesenen Mitarbeiter',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: client.assignedEmployees.map((id) {
                  final name = employeeName(id);
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Dokumente ──

  Widget _buildDocumentsTab(Client client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ClientDocumentsCard(client: client),
        ],
      ),
    );
  }

  // ── Tab 3: Teilhabe ──

  Widget _buildTeilhabeTab(Client client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildIcfBereicheCard(client),
          const SizedBox(height: 24),
          _buildTibZieleCard(client),
          const SizedBox(height: 24),
          _buildIndividuelleTibZieleCard(client),
          const SizedBox(height: 24),
          _buildNotizenCard(client),
        ],
      ),
    );
  }

  Widget _buildIcfBereicheCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.category, size: 24),
                const SizedBox(width: 12),
                Text(
                  'ICF-Bereiche',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (client.icfBereiche == null || client.icfBereiche!.isEmpty)
              Text(
                'Keine ICF-Bereiche hinterlegt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: client.icfBereiche!.map((bereich) => Chip(
                  label: Text(bereich),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTibZieleCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.flag, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Allgemeine TIB-Ziele',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (client.tibZiele == null || client.tibZiele!.isEmpty)
              Text(
                'Keine allgemeinen TIB-Ziele hinterlegt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...client.tibZiele!.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividuelleTibZieleCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.target, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Individuelle TIB-Ziele',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (client.individuelleTibZiele == null || client.individuelleTibZiele!.isEmpty)
              Text(
                'Keine individuellen TIB-Ziele hinterlegt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...client.individuelleTibZiele!.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.check_circle,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotizenCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.sticky_note_2, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Notizen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              client.notes ?? 'Keine Notizen vorhanden',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: client.notes != null
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 4: \u00dcbersicht ──

  Widget _buildUebersichtTab(Client client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFlsUebersichtCard(client),
          const SizedBox(height: 24),
          _buildKostenuebernahmeCard(client),
          const SizedBox(height: 24),
          _buildCaseManagerCard(client),
          const SizedBox(height: 24),
          _buildZeitstempelCard(client),
        ],
      ),
    );
  }

  Widget _buildFlsUebersichtCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.analytics, size: 24),
                const SizedBox(width: 12),
                Text(
                  'FLS-Verbrauchs\u00fcbersicht',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (client.fachleistungsstunden != null) ...[
              _buildFlsProgressBar(client),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Bewilligte FLS',
                      '${client.fachleistungsstunden} Std.',
                      client.fachleistungsIntervallDisplay,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricTile(
                      'Verbraucht',
                      '${client.verbrauchteStunden.toStringAsFixed(1)} Std.',
                      '${client.stundenverbrauchProzent.toStringAsFixed(0)}%',
                      client.stundenverbrauchProzent > 90 ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricTile(
                      'Verf\u00fcgbar',
                      '${client.verfuegbareStunden.toStringAsFixed(1)} Std.',
                      'Restbudget',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'Keine FLS-Daten hinterlegt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKostenuebernahmeCard(Client client) {
    int? restlaufzeit;
    if (client.kostenuebernahmeBis != null) {
      restlaufzeit = client.kostenuebernahmeBis!.difference(DateTime.now()).inDays;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.receipt_long, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Kosten\u00fcbernahme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (client.kostenuebernahme != null)
              _buildInfoRow('Kostentr\u00e4ger', client.kostenuebernahme!),
            if (client.kostenuebernahmeVon != null)
              _buildInfoRow('Von', _formatDate(client.kostenuebernahmeVon!)),
            if (client.kostenuebernahmeBis != null)
              _buildInfoRow('Bis', _formatDate(client.kostenuebernahmeBis!)),
            if (restlaufzeit != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (restlaufzeit < 30 ? Colors.red : restlaufzeit < 90 ? Colors.orange : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (restlaufzeit < 30 ? Colors.red : restlaufzeit < 90 ? Colors.orange : Colors.green).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      restlaufzeit < 30 ? Symbols.warning : Symbols.timer,
                      color: restlaufzeit < 30 ? Colors.red : restlaufzeit < 90 ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      restlaufzeit > 0
                          ? 'Restlaufzeit: $restlaufzeit Tage'
                          : 'Kosten\u00fcbernahme abgelaufen',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: restlaufzeit < 30 ? Colors.red : restlaufzeit < 90 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (client.kostenuebernahme == null && client.kostenuebernahmeVon == null)
              Text(
                'Keine Kosten\u00fcbernahme-Daten hinterlegt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseManagerCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.support_agent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Case Manager',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              client.caseManager ?? 'Kein Case Manager zugewiesen',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: client.caseManager != null
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeitstempelCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.history, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Zeitstempel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Erstellt am', _formatDateTime(client.createdAt)),
            _buildInfoRow('Aktualisiert am', _formatDateTime(client.updatedAt)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ── Actions ──

  void _showEditDialog(Client client) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(
        client: client,
        onSave: (updatedClient) async {
          await ref.read(clientProvider.notifier).updateClient(updatedClient);
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Klient wurde aktualisiert')),
            );
          }
        },
      ),
    );
  }

  void _handleMenuAction(String action, Client client) {
    switch (action) {
      case 'export':
        _exportProfilePdf(client);
        break;
      case 'print':
        _printProfile(client);
        break;
      case 'archive':
        _archiveClient(client);
        break;
      case 'activate':
        _activateClient(client);
        break;
    }
  }

  pw.Document _buildProfilePdf(Client client) {
    final employeesAsync = ref.read(employeesProvider);
    final employees = employeesAsync.valueOrNull ?? [];

    String employeeName(String? id) {
      if (id == null) return 'Nicht zugewiesen';
      final emp = employees.where((e) => e.id == id).firstOrNull;
      return emp?.fullName ?? id;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Klientenprofil', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text(client.fullName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('${client.age} Jahre - ${client.statusDisplayName}'),
          pw.Divider(),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Pers\u00f6nliche Daten'),
          _pdfRow('Geburtsdatum', _formatDate(client.dateOfBirth)),
          _pdfRow('E-Mail', client.email ?? 'Nicht angegeben'),
          _pdfRow('Telefon', client.phone ?? 'Nicht angegeben'),
          _pdfRow('Adresse', client.address ?? 'Nicht angegeben'),
          _pdfRow('Versicherungsnr.', client.insuranceNumber ?? 'Nicht angegeben'),
          _pdfRow('Notfallkontakt', client.emergencyContact ?? '-'),
          _pdfRow('Services', client.serviceDisplayNames.join(', ')),

          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Eingliederungshilfe'),
          if (client.hilfeTyp != null) _pdfRow('Hilfe-Typ', client.hilfeTypDisplay),
          if (client.fachleistungsstunden != null)
            _pdfRow('FLS', '${client.fachleistungsstunden} Std. / ${client.fachleistungsIntervallDisplay}'),
          if (client.verbrauchteStunden > 0)
            _pdfRow('Verbraucht', '${client.verbrauchteStunden.toStringAsFixed(1)} Std. (${client.stundenverbrauchProzent.toStringAsFixed(0)}%)'),
          if (client.kostenuebernahme != null)
            _pdfRow('Kostentr\u00e4ger', client.kostenuebernahme!),
          if (client.kostenuebernahmeVon != null)
            _pdfRow('Kosten\u00fcbernahme', '${_formatDate(client.kostenuebernahmeVon!)}'
                '${client.kostenuebernahmeBis != null ? ' - ${_formatDate(client.kostenuebernahmeBis!)}' : ''}'),
          if (client.betreuungSeit != null)
            _pdfRow('Betreuung seit', _formatDate(client.betreuungSeit!)),
          if (client.kalkulationsfaktorOverride != null)
            _pdfRow('Kalkulationsfaktor', '${client.kalkulationsfaktorOverride}'),
          if (client.stundensatzOverride != null)
            _pdfRow('Stundensatz', '${client.stundensatzOverride!.toStringAsFixed(2)} EUR'),

          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Zuweisungen'),
          _pdfRow('Zust\u00e4ndiger MA', employeeName(client.responsibleEmployeeId)),
          _pdfRow('Vertretung 1', employeeName(client.deputyEmployeeId)),
          _pdfRow('Vertretung 2', employeeName(client.deputy2EmployeeId)),
          if (client.caseManager != null) _pdfRow('Case Manager', client.caseManager!),
          _pdfRow('Zugewiesene MA', client.assignedEmployees.map((id) => employeeName(id)).join(', ')),

          if (client.icfBereiche != null && client.icfBereiche!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'ICF-Bereiche'),
            pw.Text(client.icfBereiche!.join(', ')),
          ],
          if (client.tibZiele != null && client.tibZiele!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Allgemeine TIB-Ziele'),
            ...client.tibZiele!.asMap().entries.map((e) =>
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('${e.key + 1}. ${e.value}', style: const pw.TextStyle(fontSize: 11)),
              ),
            ),
          ],
          if (client.individuelleTibZiele != null && client.individuelleTibZiele!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Individuelle TIB-Ziele'),
            ...client.individuelleTibZiele!.map((z) =>
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('\u2022 $z', style: const pw.TextStyle(fontSize: 11)),
              ),
            ),
          ],
          if (client.notes != null && client.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Notizen'),
            pw.Text(client.notes!),
          ],
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'Erstellt am: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Future<void> _exportProfilePdf(Client client) async {
    final pdf = _buildProfilePdf(client);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Klientenprofil_${client.lastName}_${client.firstName}.pdf',
    );
  }

  Future<void> _printProfile(Client client) async {
    final pdf = _buildProfilePdf(client);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Klientenprofil_${client.fullName}',
    );
  }

  void _archiveClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klient archivieren'),
        content: Text('M\u00f6chten Sie "${client.fullName}" archivieren?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archivieren')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(clientProvider.notifier).updateClient(
        client.copyWith(status: ClientStatus.archived, updatedAt: DateTime.now()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klient wurde archiviert')),
        );
      }
    }
  }

  void _activateClient(Client client) async {
    await ref.read(clientProvider.notifier).updateClient(
      client.copyWith(status: ClientStatus.active, updatedAt: DateTime.now()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klient wurde aktiviert')),
      );
    }
  }
}
