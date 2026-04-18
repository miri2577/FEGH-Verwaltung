import 'dart:convert';
import 'dart:typed_data';
import 'package:fegh_crypto/fegh_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import '../../services/team_key_admin_service.dart';

import '../../providers/employee_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/policy_provider.dart';
import '../../providers/hidrive_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audit_logger.dart';
import '../../services/clients_index_rebuilder.dart';
import '../../services/crypto_storage.dart';
import '../../services/admin_health_service.dart';
import '../../services/admin_repair_service.dart';
import '../../services/roles_policy_service.dart';
import '../../providers/roles_policy_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen>
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
    final policy = ref.watch(policyProvider);
    if (!policy.canViewAdminTools()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin‑Konsole')),
        body: const Center(child: Text('Keine Berechtigung')), 
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin‑Konsole'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Übersicht', icon: Icon(Symbols.dashboard)),
            Tab(text: 'Health', icon: Icon(Symbols.health_and_safety)),
            Tab(text: 'Audit', icon: Icon(Symbols.list_alt)),
            Tab(text: 'Tools', icon: Icon(Symbols.build)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildHealth(),
          _buildAudit(),
          _buildTools(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final employees = ref.watch(employeesProvider);
    final teams = ref.watch(teamsProvider);
    final clients = ref.watch(clientProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _metricCard('Mitarbeiter', employees.when(
            data: (e) => e.length,
            loading: () => 0,
            error: (_, __) => 0,
          )),
          _metricCard('Teams', teams.when(
            data: (t) => t.length,
            loading: () => 0,
            error: (_, __) => 0,
          )),
          _metricCard('Klienten', clients.length),
        ],
      ),
    );
  }

  Widget _metricCard(String title, int value) {
    return Card(
      child: SizedBox(
        width: 220,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealth() {
    final settings = ref.watch(appSettingsProvider);
    final org = settings.organizationId ?? '';
    final syncReady = settings.isCloudSyncReady;
    final client = ref.watch(hidriveClientProvider);
    final svc = AdminHealthService(client: client, orgBase: 'eingliederungshilfe/organizations/$org');
    return FutureBuilder<Map<String, bool>>(
      future: svc.check(),
      builder: (context, snapshot) {
        final checks = snapshot.data ?? const {};
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _healthRow('Org‑ID gesetzt', org.isNotEmpty),
              _healthRow('Cloud‑Sync aktiviert', syncReady),
              _healthRow('Administration erreichbar', checks['administration_access'] == true),
              _healthRow('Teams erreichbar', checks['teams_access'] == true),
              _healthRow('Rollen‑Policy vorhanden (roles.json)', checks['roles_policy_exists'] == true),
              _healthRow('Schreibrechte (Testdatei)', checks['write_access'] == true),
              const SizedBox(height: 8),
              Text('HiDrive Benutzer: ${settings.hidriveUsername ?? '–'}'),
              const SizedBox(height: 16),
              const Text('Hinweise:'),
              const Text('• Clients werden team‑scoped gespeichert (teams/<team>/clients)'),
              const Text('• Clients‑Index liegt unter administration/clients-index.bin'),
              const SizedBox(height: 16),
              _buildDriftAnalyzer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriftAnalyzer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.compare_arrows),
                const SizedBox(width: 8),
                Text('Drift‑Analyse (Index ↔ Dateien)', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _runDriftAnalysis,
                  icon: const Icon(Symbols.play_arrow),
                  label: const Text('Analysieren'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_driftResult != null) ...[
              Text('Fehlende Index‑Einträge: ${_driftResult!['missingInIndex']?.length ?? 0}'),
              Text('Veraltete Index‑Einträge: ${_driftResult!['staleInIndex']?.length ?? 0}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: (_driftResult!['missingInIndex'] as List).isEmpty ? null : _fixAddMissing,
                    icon: const Icon(Symbols.add),
                    label: const Text('Fehlende hinzufügen'),
                  ),
                  FilledButton.icon(
                    onPressed: (_driftResult!['staleInIndex'] as List).isEmpty ? null : _fixRemoveStale,
                    icon: const Icon(Symbols.delete),
                    label: const Text('Veraltete entfernen'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _driftResult;

  Future<void> _runDriftAnalysis() async {
    final org = ref.read(appSettingsProvider).organizationId ?? 'default';
    final webdav = ref.read(hidriveClientProvider);
    final crypto = ref.read(cryptoStorageProvider);
    await crypto.initialize();
    final svc = AdminRepairService(client: webdav, crypto: crypto, orgBase: 'eingliederungshilfe/organizations/$org');
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('🔎 Analysiere Drift…')));
    final result = await svc.analyzeIndexDrift();
    messenger.clearSnackBars();
    setState(() => _driftResult = result);
  }

  Future<void> _fixAddMissing() async {
    if (_driftResult == null) return;
    final items = List<Map<String, String>>.from(_driftResult!['missingInIndex'] as List);
    final org = ref.read(appSettingsProvider).organizationId ?? 'default';
    final webdav = ref.read(hidriveClientProvider);
    final crypto = ref.read(cryptoStorageProvider);
    await crypto.initialize();
    final svc = AdminRepairService(client: webdav, crypto: crypto, orgBase: 'eingliederungshilfe/organizations/$org');
    final ok = await svc.addMissingIndexEntries(items);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Fehlende Einträge hinzugefügt' : '❌ Reparatur fehlgeschlagen')));
    if (ok) await _runDriftAnalysis();
  }

  Future<void> _fixRemoveStale() async {
    if (_driftResult == null) return;
    final items = List<Map<String, String>>.from(_driftResult!['staleInIndex'] as List);
    final org = ref.read(appSettingsProvider).organizationId ?? 'default';
    final webdav = ref.read(hidriveClientProvider);
    final crypto = ref.read(cryptoStorageProvider);
    await crypto.initialize();
    final svc = AdminRepairService(client: webdav, crypto: crypto, orgBase: 'eingliederungshilfe/organizations/$org');
    final ok = await svc.removeStaleIndexEntries(items);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Veraltete Einträge entfernt' : '❌ Reparatur fehlgeschlagen')));
    if (ok) await _runDriftAnalysis();
  }

  Widget _healthRow(String label, bool ok) {
    return Row(
      children: [
        Icon(ok ? Symbols.check_circle : Symbols.warning, color: ok ? Colors.green : Colors.orange),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  final _auditSearch = TextEditingController();
  DateTimeRange? _auditRange;
  String? _auditAction;
  final Set<String> _auditKnownActions = {};

  Widget _buildAudit() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _auditSearch,
                  decoration: const InputDecoration(
                    labelText: 'Audit filtern (Text in action/ctx)',
                    prefixIcon: Icon(Symbols.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () async => _exportAudit('json'),
                icon: const Icon(Symbols.download),
                label: const Text('Als JSON exportieren'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async => _exportAudit('csv'),
                icon: const Icon(Symbols.table_chart),
                label: const Text('Als CSV exportieren'),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?> (
                value: _auditAction,
                hint: const Text('Aktion'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Alle Aktionen')),
                  ..._auditKnownActions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                ],
                onChanged: (v) => setState(() => _auditAction = v),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: now,
                    initialDateRange: _auditRange,
                  );
                  if (picked != null) setState(() => _auditRange = picked);
                },
                icon: const Icon(Symbols.calendar_month),
                label: Text(_auditRange == null ? 'Zeitraum' : '${_auditRange!.start.toLocal()} – ${_auditRange!.end.toLocal()}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _loadFilteredAudit(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lines = snapshot.data!;
                if (lines.isEmpty) {
                  return const Center(child: Text('Keine passenden Audit‑Einträge'));
                }
                return Scrollbar(
                  child: SingleChildScrollView(
                    child: SelectableText(lines.join('\n')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _loadFilteredAudit() async {
    final lines = await AuditLogger.tail(lines: 2000);
    final q = _auditSearch.text.trim().toLowerCase();
    DateTime? start = _auditRange?.start;
    DateTime? end = _auditRange?.end;
    final out = <String>[];
    for (final line in lines) {
      try {
        final obj = jsonDecode(line) as Map<String, dynamic>;
        final ts = DateTime.tryParse(obj['ts'] as String? ?? '')?.toLocal();
        if (start != null && ts != null && ts.isBefore(start)) continue;
        if (end != null && ts != null && ts.isAfter(end.add(const Duration(days: 1)))) continue;
        final actionRaw = (obj['action']?.toString() ?? '');
        final action = actionRaw.toLowerCase();
        _auditKnownActions.add(actionRaw);
        final ctx = jsonEncode(obj['ctx'] ?? {}).toLowerCase();
        if (_auditAction != null && actionRaw != _auditAction) continue;
        if (q.isNotEmpty && !(action.contains(q) || ctx.contains(q))) continue;
        out.add(line);
      } catch (_) {
        if (q.isEmpty || line.toLowerCase().contains(q)) out.add(line);
      }
    }
    return out;
  }

  Future<void> _exportAudit(String format) async {
    try {
      final filtered = await _loadFilteredAudit();
      final bytes = format == 'csv' ? utf8.encode(_toCsv(filtered)) : utf8.encode(filtered.join('\n'));
      final ext = format == 'csv' ? 'csv' : 'json';
      final mime = format == 'csv' ? 'text/csv' : 'application/json';
      final fileName = 'audit_filtered_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: ext,
        mimeType: ext == 'csv' ? MimeType.csv : MimeType.json,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Audit exportiert: $fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Export‑Fehler: $e')));
      }
    }
  }

  String _toCsv(List<String> lines) {
    final buffer = StringBuffer('ts,action,ctx\n');
    for (final line in lines) {
      try {
        final obj = jsonDecode(line) as Map<String, dynamic>;
        final ts = obj['ts'] ?? '';
        final action = (obj['action'] ?? '').toString().replaceAll(',', ' ');
        final ctx = jsonEncode(obj['ctx'] ?? {}).replaceAll(',', ';');
        buffer.writeln('$ts,$action,$ctx');
      } catch (_) {
        final sanitized = line.replaceAll(',', ' ');
        buffer.writeln(',,"$sanitized"');
      }
    }
    return buffer.toString();
  }

  Widget _buildTools() {
    final policy = ref.watch(policyProvider);
    final canRebuild = policy.canRebuildIndexes();
    final canRotate = policy.canRotateKeys();
    final rolesSvc = ref.watch(rolesPolicyProvider);
    final rolesEditorCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: canRebuild ? _rebuildClientsIndex : null,
            icon: const Icon(Symbols.storage),
            label: const Text('Clients‑Index neu aufbauen'),
          ),
          FilledButton.icon(
            onPressed: canRotate ? _showTeamKeyQr : null,
            icon: const Icon(Symbols.qr_code_2),
            label: const Text('Team‑Key als QR'),
          ),
          FilledButton.icon(
            onPressed: canRotate ? _showProvisioningQr : null,
            icon: const Icon(Symbols.qr_code_scanner),
            label: const Text('Mitarbeiter provisionieren (QR)'),
          ),
          // Rollen‑Policy Editor (einfach)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Symbols.admin_panel_settings),
                        const SizedBox(width: 8),
                        Text('Rollen‑Policy (roles.json)', style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final obj = await rolesSvc.loadRaw();
                            if (!mounted) return;
                            if (obj == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ℹ️ Keine roles.json gefunden')));
                              return;
                            }
                            rolesEditorCtrl.text = const JsonEncoder.withIndent('  ').convert(obj);
                          },
                          icon: const Icon(Symbols.download),
                          label: const Text('Laden'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              final text = rolesEditorCtrl.text.trim();
                              final obj = text.isEmpty
                                  ? {
                                      'users': [
                                        {
                                          'id': (ref.read(appSettingsProvider).hidriveUsername ?? '').toLowerCase(),
                                          'role': 'org_admin',
                                          'teams': <String>[],
                                        }
                                      ]
                                    }
                                  : (jsonDecode(text) as Map<String, dynamic>);
                              final ok = await rolesSvc.save(obj);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Rollen‑Policy gespeichert' : '❌ Speichern fehlgeschlagen')));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ungültiges JSON: $e')));
                            }
                          },
                          icon: const Icon(Symbols.upload),
                          label: const Text('Speichern'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rolesEditorCtrl,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '{\n  "users": [ { "id": "user@example.com", "role": "org_admin", "teams": ["team-a"] } ]\n}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Auditor JIT-Leserechte (zeitlich/teams begrenzt)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 560,
                child: _AuditorScopeEditor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rebuildClientsIndex() async {
    final org = ref.read(appSettingsProvider).organizationId ?? 'default';
    final client = ref.read(hidriveClientProvider);
    final crypto = ref.read(cryptoStorageProvider);
    await crypto.initialize();
    final svc = ClientsIndexRebuilder(client: client, crypto: crypto, orgBase: 'eingliederungshilfe/organizations/$org');
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('🔧 Baue Clients‑Index neu auf…')));
    final count = await svc.rebuild();
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text('✅ Clients‑Index neu aufgebaut ($count Einträge)')));
    await AuditLogger.log('clients.index.rebuild', context: {'count': count});
  }

  void _showTeamKeyQr() {
    final ctrl = TextEditingController();
    String? qrData;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Team‑Key als QR anzeigen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Team ID')),
              const SizedBox(height: 12),
              if (qrData != null) SelectableText(qrData!),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
            FilledButton(
              onPressed: () async {
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final client = ref.read(hidriveClientProvider);
                final crypto = ref.read(cryptoStorageProvider);
                await crypto.initialize();
                final svc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                final b64 = await svc.fetchTeamKeyBase64(ctrl.text.trim());
                if (b64 == null || b64.isEmpty) return;
                final payload = jsonEncode({'type': 'egh-team-key', 'org': org, 'team': ctrl.text.trim(), 'key': b64, 'ts': DateTime.now().toUtc().toIso8601String()});
                setState(() => qrData = payload);
              },
              child: const Text('QR‑Payload anzeigen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProvisioningQr() {
    final emailCtrl = TextEditingController();
    String role = 'team_member';
    final teamsCtrl = TextEditingController();
    final appPwdCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    Uint8List? qrPng;
    String? payload;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Provisioning‑QR (Mitarbeiter)'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'HiDrive Benutzer (E‑Mail/login)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'team_member', child: Text('Team‑Member')),
                    DropdownMenuItem(value: 'team_lead', child: Text('Team‑Lead')),
                    DropdownMenuItem(value: 'org_auditor', child: Text('Org‑Auditor')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? role),
                  decoration: const InputDecoration(labelText: 'Rolle'),
                ),
                const SizedBox(height: 8),
                TextField(controller: teamsCtrl, decoration: const InputDecoration(labelText: 'Teams (kommagetrennt, z. B. team-a,team-b)')),
                const SizedBox(height: 8),
                TextField(controller: appPwdCtrl, decoration: const InputDecoration(labelText: 'HiDrive App‑Passwort (optional)'), obscureText: true),
                const SizedBox(height: 8),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Schutz-PIN (6 Ziffern)',
                    helperText: 'Der Mitarbeiter gibt diese PIN in der Doku-App beim Scannen ein',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                if (qrPng != null)
                  Image.memory(qrPng!, width: 220, height: 220),
                if (payload != null) ...[
                  const SizedBox(height: 8),
                  SelectableText(payload!, style: const TextStyle(fontSize: 12)),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
            FilledButton(
              onPressed: () async {
                final email = emailCtrl.text.trim().toLowerCase();
                if (email.isEmpty) return;
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final client = ref.read(hidriveClientProvider);
                final crypto = ref.read(cryptoStorageProvider);
                await crypto.initialize();
                final teamSvc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                // Teams parsen (wird mehrfach benötigt)
                final teams = teamsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                // Rolle in roles.json eintragen/aktualisieren
                try {
                  final rolesSvc = ref.read(rolesPolicyProvider);
                  final raw = await rolesSvc.loadRaw() ?? {'users': <Map<String, dynamic>>[]};
                  final users = List<Map<String, dynamic>>.from((raw['users'] as List?) ?? <Map<String, dynamic>>[]);
                  final idx = users.indexWhere((u) => (u['id'] ?? '').toString().toLowerCase() == email);
                  final newEntry = {'id': email, 'role': role, 'teams': teams};
                  if (idx >= 0) {
                    users[idx] = newEntry;
                  } else {
                    users.add(newEntry);
                  }
                  final saved = await rolesSvc.save({'users': users});
                  if (!saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ roles.json konnte nicht gespeichert werden')));
                  }
                } catch (_) {}
                final Map<String, String> teamKeys = {};
                for (final t in teams) {
                  await teamSvc.ensureTeamKey(t);
                  final k = await teamSvc.fetchTeamKeyBase64(t);
                  if (k != null && k.isNotEmpty) teamKeys[t] = k;
                }
                final appPwd = appPwdCtrl.text.trim();
                final pin = pinCtrl.text.trim();
                if (pin.length < 6) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN muss mindestens 6 Ziffern haben')),
                    );
                  }
                  return;
                }
                // Token mit PIN verschluesseln (Format kompatibel zur Doku-App)
                final token = ProvisioningToken(
                  org: org,
                  user: email,
                  role: role,
                  teams: teams,
                  teamKeys: teamKeys,
                  hidrive: HidriveCredentials(
                    username: email,
                    appPassword: appPwd.isEmpty ? null : appPwd,
                  ),
                  flags: const {
                    'managed': true,
                    'hideCredentials': true,
                    'forceInitialSync': true,
                  },
                  ts: DateTime.now().toUtc(),
                );
                final data = await token.encryptWithPin(pin);
                payload = data;
                try {
                  final painter = QrPainter(data: data, version: QrVersions.auto, gapless: true);
                  final dataBytes = await painter.toImageData(360, format: ui.ImageByteFormat.png);
                  qrPng = dataBytes?.buffer.asUint8List();
                } catch (_) {
                  qrPng = null;
                }
                if (context.mounted) setState(() {});
              },
              child: const Text('QR erzeugen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditorScopeEditor extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AuditorScopeEditor> createState() => _AuditorScopeEditorState();
}

class _AuditorScopeEditorState extends ConsumerState<_AuditorScopeEditor> {
  final _auditorCtrl = TextEditingController();
  final _teamsCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  Map<String, dynamic>? _rolesRaw;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final svc = ref.read(rolesPolicyProvider);
    final raw = await svc.loadRaw();
    setState(() => _rolesRaw = raw);
  }

  List<String> _auditorsFromRaw() {
    final users = (_rolesRaw?['users'] as List?) ?? const [];
    final out = <String>[];
    for (final u in users) {
      if (u is Map<String, dynamic>) {
        final role = (u['role'] ?? '').toString();
        if (role.toLowerCase() == 'org_auditor') {
          out.add((u['id'] ?? '').toString());
        }
      }
    }
    return out..sort();
  }

  @override
  Widget build(BuildContext context) {
    final auditors = _auditorsFromRaw();
    final rolesSvc = ref.watch(rolesPolicyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Symbols.visibility),
            const SizedBox(width: 8),
            Text('Auditor‑Leserechte (JIT)', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _loadRoles,
              icon: const Icon(Symbols.refresh),
              label: const Text('Rollen laden'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: auditors.contains(_auditorCtrl.text) ? _auditorCtrl.text : null,
          items: auditors.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _auditorCtrl.text = v ?? ''),
          decoration: const InputDecoration(labelText: 'Auditor (User‑ID)'),
        ),
        const SizedBox(height: 8),
        TextField(controller: _teamsCtrl, decoration: const InputDecoration(labelText: 'Teams (kommagetrennt)')), 
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 2),
                    initialDateRange: _from != null && _to != null ? DateTimeRange(start: _from!, end: _to!) : null,
                  );
                  if (picked != null) setState(() { _from = picked.start; _to = picked.end; });
                },
                icon: const Icon(Symbols.schedule),
                label: Text(_from == null || _to == null ? 'Zeitraum wählen' : '${_from!.toLocal()} – ${_to!.toLocal()}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(controller: _reasonCtrl, decoration: const InputDecoration(labelText: 'Begründung (wird geloggt)')),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: () async {
                final user = _auditorCtrl.text.trim().toLowerCase();
                if (user.isEmpty) return;
                final teams = _teamsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                final scope = AuditScope(teams: teams, from: _from?.toUtc(), to: _to?.toUtc(), reason: _reasonCtrl.text.trim());
                final ok = await rolesSvc.setAuditorScope(userId: user, scope: scope);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Auditor‑Scope gesetzt' : '❌ Speichern fehlgeschlagen')));
                }
                if (ok) await AuditLogger.log('auditor.scope.set', context: {'user': user, 'teams': teams, 'from': _from?.toIso8601String(), 'to': _to?.toIso8601String(), 'reason': _reasonCtrl.text.trim()});
              },
              icon: const Icon(Symbols.check),
              label: const Text('Aktivieren'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final user = _auditorCtrl.text.trim().toLowerCase();
                if (user.isEmpty) return;
                final ok = await rolesSvc.clearAuditorScope(user);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Auditor‑Scope entfernt' : '❌ Entfernen fehlgeschlagen')));
                }
                if (ok) await AuditLogger.log('auditor.scope.clear', context: {'user': user});
              },
              icon: const Icon(Symbols.delete),
              label: const Text('Deaktivieren'),
            ),
          ],
        ),
      ],
    );
  }
}
