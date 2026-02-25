import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart';
import '../../models/app_settings.dart';
import '../../models/ui_customization.dart';
import '../../providers/hidrive_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/team_key_admin_service.dart';
import '../../services/rewrap_service.dart';
import '../../services/clients_index_rebuilder.dart';
import '../../services/audit_logger.dart';
import '../../providers/policy_provider.dart';
import '../admin/admin_console_screen.dart';
import '../../providers/roles_policy_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/timesheet_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/vacation_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _hidriveUsernameController = TextEditingController();
  final _hidrivePasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _hidriveUsernameController.dispose();
    _hidrivePasswordController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final settings = ref.read(appSettingsProvider);
    if (settings.hidriveUsername != null) {
      _hidriveUsernameController.text = settings.hidriveUsername!;
    }
    // Passwort wird nicht vorgeladen – nur bei Änderung neu eingeben
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.settings,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Einstellungen',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCloudSyncSection(settings),
                    const SizedBox(height: 32),
                    _buildSyncSettingsSection(settings),
                    const SizedBox(height: 32),
                    _buildUISettingsSection(settings),
                    const SizedBox(height: 32),
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudSyncSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cloud-Synchronisation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hidriveUsernameController,
                    decoration: const InputDecoration(
                      labelText: 'HiDrive Benutzername',
                      hintText: 'ihre-email@example.com',
                      prefixIcon: Icon(Symbols.account_circle),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _hidrivePasswordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'HiDrive Passwort',
                      hintText: settings.hidrivePassword != null ? 'Gespeichert – neu eingeben zum Ändern' : 'Passwort eingeben',
                      prefixIcon: const Icon(Symbols.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Symbols.visibility_off : Symbols.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: (ref.read(appSettingsProvider).userRole ?? 'org_admin'),
                    items: const [
                      DropdownMenuItem(value: 'org_admin', child: Text('Rolle: Org‑Admin')),
                      DropdownMenuItem(value: 'org_auditor', child: Text('Rolle: Org‑Auditor')),
                      DropdownMenuItem(value: 'team_lead', child: Text('Rolle: Team‑Lead')),
                      DropdownMenuItem(value: 'team_member', child: Text('Rolle: Team‑Member')),
                      DropdownMenuItem(value: 'pv_admin', child: Text('Rolle: PV‑Admin')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      final s = ref.read(appSettingsProvider);
                      await ref.read(settingsServiceProvider).saveSettings(
                        s.copyWith(userRole: v, updatedAt: DateTime.now()),
                      );
                      setState(() {});
                    },
                  ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final svc = ref.read(rolesPolicyProvider);
                  final ok = await svc.refresh();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Rollen‑Policy geladen' : 'Keine Rollen‑Policy gefunden')),
                  );
                  setState(() {});
                },
                icon: const Icon(Symbols.sync),
                label: const Text('Rollen‑Policy aktualisieren'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Organisation/Träger ID',
                    hintText: 'z. B. dasi',
                      prefixIcon: Icon(Symbols.corporate_fare),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) async {
                      final s = ref.read(appSettingsProvider);
                      await ref.read(settingsServiceProvider).saveSettings(
                        s.copyWith(organizationId: v.trim(), updatedAt: DateTime.now()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Root‑Unterordner (optional)',
                      hintText: 'z. B. Gemeinsam/Eingliederungshilfe',
                      prefixIcon: Icon(Symbols.folder),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: ref.read(appSettingsProvider).rootSubdirectory ?? ''),
                    onSubmitted: (v) async {
                      final s = ref.read(appSettingsProvider);
                      await ref.read(settingsServiceProvider).saveSettings(
                        s.copyWith(rootSubdirectory: v.trim().isEmpty ? null : v.trim(), updatedAt: DateTime.now()),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: Text(
                    'Nur verwenden, wenn der Organisations‑Ordner als Freigabe unter einem Unterpfad gemountet ist (z. B. „Gemeinsam“).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials ? () => _showPassphraseDialog(context, ref) : null,
                  icon: const Icon(Symbols.vpn_key),
                  label: const Text('Sync‑Passphrase setzen'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials && ref.read(policyProvider).canRotateKeys() ? () => _showTeamKeyDialog(context, ref) : null,
                  icon: const Icon(Symbols.key),
                  label: const Text('Team‑Key erzeugen'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials && ref.read(policyProvider).canRotateKeys() ? () => _showTeamKeyQrDialog(context, ref) : null,
                  icon: const Icon(Symbols.qr_code_2),
                  label: const Text('Team‑Key als QR'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials && ref.read(policyProvider).canRebuildIndexes() ? () => _rebuildClientsIndex(ref) : null,
                  icon: const Icon(Symbols.storage),
                  label: const Text('Clients‑Index neu aufbauen'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: ref.read(policyProvider).canViewAdminTools() ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
                    );
                  } : null,
                  icon: const Icon(Symbols.admin_panel_settings),
                  label: const Text('Admin‑Konsole'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: ref.read(policyProvider).canViewAdminTools() ? _showAuditLogDialog : null,
                  icon: const Icon(Symbols.list_alt),
                  label: const Text('Audit‑Log ansehen'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials ? () => _showRewrapDialog(context, ref) : null,
                  icon: const Icon(Symbols.lock_reset),
                  label: const Text('Team‑Records rewrap'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: settings.hasHiDriveCredentials ? () => _showSendMessageDialog(context, ref) : null,
                  icon: const Icon(Symbols.send),
                  label: const Text('Nachricht senden'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _saveHiDriveCredentials,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.save, size: 18),
                  label: const Text('Anmeldedaten speichern'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: settings.hasHiDriveCredentials ? _testConnection : null,
                  icon: const Icon(Symbols.wifi_protected_setup, size: 18),
                  label: const Text('Verbindung testen'),
                ),
                const Spacer(),
                Switch(
                  value: settings.enableCloudSync,
                  onChanged: _toggleCloudSync,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cloud-Sync ${settings.enableCloudSync ? 'aktiviert' : 'deaktiviert'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  settings.isCloudSyncReady ? Symbols.check_circle : Symbols.warning,
                  color: settings.isCloudSyncReady ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.isCloudSyncReady
                      ? 'Cloud-Synchronisation ist bereit'
                      : 'Anmeldedaten erforderlich für Cloud-Sync',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: settings.isCloudSyncReady ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (settings.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Letzte Synchronisation: ${DateTime.parse(settings.lastSyncTime!).toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rebuildClientsIndex(WidgetRef ref) async {
    try {
      if (!ref.read(policyProvider).canRebuildIndexes()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Berechtigung')));
        return;
      }
      final org = ref.read(appSettingsProvider).organizationId ?? 'default';
      final client = ref.read(hidriveClientProvider);
      final crypto = ref.read(cryptoStorageProvider);
      await crypto.initialize();
      final svc = ClientsIndexRebuilder(
        client: client,
        crypto: crypto,
        orgBase: 'eingliederungshilfe/organizations/$org',
      );
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('🔧 Baue Clients‑Index neu auf…')));
      final count = await svc.rebuild();
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text('✅ Clients‑Index neu aufgebaut ($count Einträge)')));
      await AuditLogger.log('clients.index.rebuild', context: {'count': count});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
    }
  }

  void _showAuditLogDialog() async {
    final lines = await AuditLogger.tail(lines: 300);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit‑Log (letzte 300 Zeilen)'),
        content: SizedBox(
          width: 700,
          height: 400,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: SelectableText(lines.isEmpty ? 'Keine Einträge' : lines.join('\n')),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
        ],
      ),
    );
  }

  void _showPassphraseDialog(BuildContext context, WidgetRef ref) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final ok = _valid(c1.text);
          return AlertDialog(
            title: const Text('Sync‑Passphrase setzen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c1,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Passphrase'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: c2,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Passphrase wiederholen'),
                ),
                const SizedBox(height: 8),
                const Text('Mindestanforderung: ≥ 12 Zeichen, mind. 3 Zeichenklassen.'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
              FilledButton(
                onPressed: ok && c1.text == c2.text ? () async {
                  Navigator.pop(context);
                  try {
                    final crypto = ref.read(cryptoStorageProvider);
                    await crypto.initialize();
                    crypto.setExternalPassphrase(c1.text.trim());
                    await crypto.rotateMEK();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Passphrase gesetzt')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
                    }
                  }
                } : null,
                child: const Text('Setzen'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTeamKeyDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team‑Key erzeugen/anzeigen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Team ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              readOnly: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Team‑Key (Base64)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          OutlinedButton(
            onPressed: () async {
              final teamId = ctrl.text.trim();
              if (teamId.isEmpty) return;
              try {
                final crypto = ref.read(cryptoStorageProvider);
                final client = ref.read(hidriveClientProvider);
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final svc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                final b64 = await svc.fetchTeamKeyBase64(teamId);
                if (b64 != null && context.mounted) {
                  keyController.text = b64;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Team‑Key geladen')));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ℹ️ Kein Team‑Key vorhanden')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
                }
              }
            },
            child: const Text('Anzeigen'),
          ),
          FilledButton(
            onPressed: () async {
              final teamId = ctrl.text.trim();
              if (teamId.isEmpty) return;
              Navigator.pop(context);
              try {
                final crypto = ref.read(cryptoStorageProvider);
                final client = ref.read(hidriveClientProvider);
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final svc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                final ok = await svc.ensureTeamKey(teamId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Team‑Key erzeugt' : '❌ Team‑Key fehlgeschlagen')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
                }
              }
            },
            child: const Text('Erzeugen'),
          ),
        ],
      ),
    );
  }

  bool _valid(String s) {
    if (s.length < 12) return false;
    final l = RegExp(r'[a-z]').hasMatch(s);
    final u = RegExp(r'[A-Z]').hasMatch(s);
    final d = RegExp(r'[0-9]').hasMatch(s);
    final sp = RegExp(r'[^A-Za-z0-9]').hasMatch(s);
    return [l, u, d, sp].where((v) => v).length >= 3;
  }

  void _showSendMessageDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht senden'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Betreff'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Nachricht', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final body = bodyCtrl.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              Navigator.pop(context);
              try {
                final crypto = ref.read(cryptoStorageProvider);
                final client = ref.read(hidriveClientProvider);
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                final payload = {
                  'id': id,
                  'title': title,
                  'body': body,
                  'flags': <String>[],
                  'createdAt': DateTime.now().toUtc().toIso8601String(),
                  'senderId': ref.read(appSettingsProvider).hidriveUsername ?? 'unknown',
                  'senderName': ref.read(appSettingsProvider).hidriveUsername ?? 'Unbekannt',
                  'isRead': false,
                  'priority': 'normal',
                  'type': 'announcement',
                };
                final enc = await crypto.encryptJson('message', payload);
                final bytes = Uint8List.fromList(utf8.encode(enc));
                final path = 'eingliederungshilfe/organizations/$org/shared/messages/$id.bin';
                await client.mkcol('eingliederungshilfe/organizations/$org/shared/messages');
                final res = await client.put(path, bytes);
                if (res.success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Nachricht gesendet')));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Senden fehlgeschlagen')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
                }
              }
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettingsSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.sync,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sync-Einstellungen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Automatisch bei App-Start synchronisieren'),
              subtitle: const Text('Lädt Änderungen aus der Cloud beim App-Start'),
              value: settings.autoSyncOnStartup,
              onChanged: (value) => _updateSyncSettings(autoSyncOnStartup: value),
            ),
            SwitchListTile(
              title: const Text('Automatisch bei Änderungen synchronisieren'),
              subtitle: const Text('Speichert Änderungen sofort in der Cloud'),
              value: settings.autoSyncOnChanges,
              onChanged: (value) => _updateSyncSettings(autoSyncOnChanges: value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Sync-Intervall: ${settings.syncIntervalMinutes} Minuten',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _showSyncIntervalDialog,
                  icon: const Icon(Symbols.schedule, size: 18),
                  label: const Text('Ändern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUISettingsSection(AppSettings settings) {
    final ui = settings.uiCustomization;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Benutzeroberfläche',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Dunkles Theme'),
              subtitle: const Text('Verwendet dunkle Farben für bessere Sicht bei wenig Licht'),
              value: settings.enableDarkMode,
              onChanged: (value) => _toggleDarkMode(value),
            ),
            SwitchListTile(
              title: const Text('Benachrichtigungen'),
              subtitle: const Text('Zeigt Benachrichtigungen für wichtige Ereignisse'),
              value: settings.enableNotifications,
              onChanged: (value) => _toggleNotifications(value),
            ),
            SwitchListTile(
              title: const Text('Auditor darf Dokumentation lesen'),
              subtitle: const Text('Erlaubt Lesezugriff auf ICF/TIB für Org‑Auditoren'),
              value: settings.auditorCanViewDocs,
              onChanged: (value) async {
                final s = ref.read(appSettingsProvider);
                await ref.read(settingsServiceProvider).saveSettings(
                  s.copyWith(auditorCanViewDocs: value, updatedAt: DateTime.now()),
                );
              },
            ),
            const Divider(height: 32),

            // UI-Dichte Preset
            Text('UI-Dichte', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<UIDensityPreset>(
              segments: const [
                ButtonSegment(value: UIDensityPreset.compact, label: Text('Kompakt'), icon: Icon(Icons.density_small)),
                ButtonSegment(value: UIDensityPreset.standard, label: Text('Standard'), icon: Icon(Icons.density_medium)),
                ButtonSegment(value: UIDensityPreset.comfortable, label: Text('Komfortabel'), icon: Icon(Icons.density_large)),
              ],
              selected: {ui.densityPreset},
              onSelectionChanged: (selected) {
                final preset = selected.first;
                final newUi = UICustomization.fromPreset(preset).copyWith(
                  tabDisplayMode: ui.tabDisplayMode,
                  cardStyle: ui.cardStyle,
                );
                _updateUICustomization(newUi);
              },
            ),
            const SizedBox(height: 24),

            // Feineinstellungen
            ExpansionTile(
              leading: const Icon(Icons.tune),
              title: const Text('Feineinstellungen'),
              tilePadding: EdgeInsets.zero,
              children: [
                _buildSliderRow('Schriftgroesse', ui.fontScale, 0.8, 1.4, 12,
                    '${(ui.fontScale * 100).round()}%',
                    UICustomization.fromPreset(ui.densityPreset).fontScale,
                    (v) => _updateUICustomization(ui.copyWith(fontScale: v))),
                _buildSliderRow('Zeilenabstand', ui.lineHeightScale, 1.0, 1.6, 6,
                    ui.lineHeightScale.toStringAsFixed(1),
                    UICustomization.fromPreset(ui.densityPreset).lineHeightScale,
                    (v) => _updateUICustomization(ui.copyWith(lineHeightScale: v))),
                _buildSliderRow('Abstaende/Padding', ui.spacingScale, 0.7, 1.5, 16,
                    '${(ui.spacingScale * 100).round()}%',
                    UICustomization.fromPreset(ui.densityPreset).spacingScale,
                    (v) => _updateUICustomization(ui.copyWith(spacingScale: v))),
                _buildSliderRow('Tabellenzeilen-Hoehe', ui.tableRowHeight, 36, 64, 7,
                    '${ui.tableRowHeight.round()} px',
                    UICustomization.fromPreset(ui.densityPreset).tableRowHeight,
                    (v) => _updateUICustomization(ui.copyWith(tableRowHeight: v))),
              ],
            ),
            const SizedBox(height: 16),

            // Layout-Praeferenzen
            ExpansionTile(
              leading: const Icon(Icons.view_quilt),
              title: const Text('Layout-Praeferenzen'),
              tilePadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tab-Darstellung'),
                      const SizedBox(height: 8),
                      SegmentedButton<TabDisplayMode>(
                        segments: const [
                          ButtonSegment(value: TabDisplayMode.iconAndText, label: Text('Icon+Text')),
                          ButtonSegment(value: TabDisplayMode.iconOnly, label: Text('Nur Icon')),
                          ButtonSegment(value: TabDisplayMode.textOnly, label: Text('Nur Text')),
                        ],
                        selected: {ui.tabDisplayMode},
                        onSelectionChanged: (s) => _updateUICustomization(ui.copyWith(tabDisplayMode: s.first)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Karten-Stil'),
                      const SizedBox(height: 8),
                      SegmentedButton<CardStyle>(
                        segments: const [
                          ButtonSegment(value: CardStyle.outlined, label: Text('Rahmen')),
                          ButtonSegment(value: CardStyle.elevated, label: Text('Erhoeht')),
                          ButtonSegment(value: CardStyle.flat, label: Text('Flach')),
                        ],
                        selected: {ui.cardStyle},
                        onSelectionChanged: (s) => _updateUICustomization(ui.copyWith(cardStyle: s.first)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tabellen-Dichte'),
                      const SizedBox(height: 8),
                      SegmentedButton<TableDensity>(
                        segments: const [
                          ButtonSegment(value: TableDensity.compact, label: Text('Kompakt')),
                          ButtonSegment(value: TableDensity.standard, label: Text('Standard')),
                          ButtonSegment(value: TableDensity.comfortable, label: Text('Grosszuegig')),
                        ],
                        selected: {ui.tableDensity},
                        onSelectionChanged: (s) {
                          final rowHeight = switch (s.first) {
                            TableDensity.compact => 36.0,
                            TableDensity.standard => 48.0,
                            TableDensity.comfortable => 56.0,
                          };
                          _updateUICustomization(ui.copyWith(tableDensity: s.first, tableRowHeight: rowHeight));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vorschau
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vorschau', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text('Dies ist ein Beispieltext in der aktuellen Schriftgroesse.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('Kleinerer Text als Referenz.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Zuruecksetzen
            OutlinedButton.icon(
              onPressed: () => _updateUICustomization(const UICustomization()),
              icon: const Icon(Icons.restore),
              label: const Text('UI auf Standard zuruecksetzen'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Sprache: ${settings.language}', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text('Datumsformat: ${settings.dateFormat}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, int divisions,
      String displayValue, double defaultValue, ValueChanged<double> onChanged) {
    final isDefault = (value - defaultValue).abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(displayValue, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              if (!isDefault)
                IconButton(
                  icon: const Icon(Icons.restore, size: 18),
                  onPressed: () => onChanged(defaultValue),
                  tooltip: 'Zuruecksetzen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _updateUICustomization(UICustomization ui) async {
    await ref.read(appSettingsProvider.notifier).updateUICustomization(ui);
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Über die App',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Personalverwaltung - Eingliederungshilfe'),
            const Text('Version 1.0.0'),
            const Text('Entwickelt für die effiziente Verwaltung von Personal in der Eingliederungshilfe'),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showDataExportDialog,
                  icon: const Icon(Symbols.download, size: 18),
                  label: const Text('Daten exportieren'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showResetDialog,
                  icon: const Icon(Symbols.restore, size: 18),
                  label: const Text('Einstellungen zurücksetzen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHiDriveCredentials() async {
    final username = _hidriveUsernameController.text.trim();
    final password = _hidrivePasswordController.text.trim();
    final existingPassword = ref.read(appSettingsProvider).hidrivePassword;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte geben Sie einen Benutzernamen ein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.isEmpty && existingPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte geben Sie ein Passwort ein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsService = ref.read(settingsServiceProvider);
      final success = await settingsService.updateHiDriveCredentials(
        username,
        password.isNotEmpty ? password : existingPassword!,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anmeldedaten erfolgreich gespeichert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Fehler beim Speichern der Anmeldedaten');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _testConnection() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('🔌 Teste HiDrive‑Verbindung…')),
    );

    try {
      final client = ref.read(hidriveClientProvider);
      final org = ref.read(appSettingsProvider).organizationId ?? 'default';

      // 1) Basis (User‑Root)
      final root = await client.propfind('', depth: 0);
      if (!root.success) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(content: Text('❌ Verbindung fehlgeschlagen: ${root.error ?? root.statusCode}'), backgroundColor: Colors.red),
        );
        return;
      }

      // 2) App‑Basis
      final appBase = await client.propfind('eingliederungshilfe/', depth: 0);

      // 3) Orga‑Pfad
      final orgPath = 'eingliederungshilfe/organizations/$org/';
      final orgRes = await client.propfind(orgPath, depth: 0);

      messenger.clearSnackBars();
      if (orgRes.success) {
        messenger.showSnackBar(
          SnackBar(content: Text('✅ Verbindung ok • Orga‑Pfad erreichbar: $org')),);
      } else if (appBase.success) {
        messenger.showSnackBar(
          SnackBar(content: Text('✅ Verbindung ok • Orga‑Ordner fehlt → bitte Sync ausführen'), backgroundColor: Colors.orange),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('✅ Verbindung ok • Ordner werden per Sync angelegt'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Fehler beim Verbindungstest: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleCloudSync(bool value) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.enableCloudSync(value);
  }

  Future<void> _updateSyncSettings({
    bool? autoSyncOnStartup,
    bool? autoSyncOnChanges,
    int? syncIntervalMinutes,
  }) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.updateSyncSettings(
      autoSyncOnStartup: autoSyncOnStartup,
      autoSyncOnChanges: autoSyncOnChanges,
      syncIntervalMinutes: syncIntervalMinutes,
    );
  }

  Future<void> _toggleDarkMode(bool value) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.updateUISettings(enableDarkMode: value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.updateUISettings(enableNotifications: value);
  }

  void _showSyncIntervalDialog() {
    final currentInterval = ref.read(appSettingsProvider).syncIntervalMinutes;
    int newInterval = currentInterval;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sync-Intervall ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aktuelles Intervall: $newInterval Minuten'),
              const SizedBox(height: 16),
              Slider(
                value: newInterval.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: '$newInterval min',
                onChanged: (value) {
                  setDialogState(() {
                    newInterval = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateSyncSettings(syncIntervalMinutes: newInterval);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.download),
            SizedBox(width: 12),
            Text('Daten exportieren'),
          ],
        ),
        content: const SizedBox(
          width: 400,
          child: Text('Alle Daten (Mitarbeiter, Zeitnachweise, Schichten, Urlaubsanträge) werden als JSON-Datei exportiert.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performDataExport();
            },
            icon: const Icon(Symbols.download),
            label: const Text('Exportieren'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataExport() async {
    try {
      final employees = ref.read(employeesProvider).valueOrNull ?? [];
      final timesheets = ref.read(timesheetsProvider).valueOrNull ?? [];
      final shifts = ref.read(shiftsProvider).valueOrNull ?? [];
      final vacations = ref.read(vacationRequestsProvider).valueOrNull ?? [];

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'employees': employees.map((e) => e.toJson()).toList(),
        'timesheets': timesheets.map((t) => t.toJson()).toList(),
        'shifts': shifts.map((s) => s.toJson()).toList(),
        'vacationRequests': vacations.map((v) => v.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Daten exportieren',
        fileName: 'personalverwaltung_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daten exportiert: ${employees.length} Mitarbeiter, ${timesheets.length} Zeitnachweise, ${shifts.length} Schichten, ${vacations.length} Urlaubsanträge'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Export: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einstellungen zurücksetzen'),
        content: const Text('Möchten Sie alle Einstellungen auf die Standardwerte zurücksetzen? Dies betrifft nicht Ihre Daten, nur die Einstellungen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final settingsService = ref.read(settingsServiceProvider);
              await settingsService.resetSettings();
              _loadCurrentSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Einstellungen wurden zurückgesetzt'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  void _showTeamKeyQrDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final teamsCtrl = TextEditingController();
    String? qrData;
    String? keyPreview;
    String? errorText;
    bool isLoading = false;
    Uint8List? qrPng;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Team‑Key als QR anzeigen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Team ID'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Optional-Felder (Rolle/Teams) – für QR-Provisionierung der Mobile-App
              DropdownButtonFormField<String?>(
                value: null,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Keine Rolle mitsenden')),
                  DropdownMenuItem(value: 'org_admin', child: Text('Rolle: Org‑Admin')),
                  DropdownMenuItem(value: 'pv_admin', child: Text('Rolle: PV‑Admin')),
                  DropdownMenuItem(value: 'org_auditor', child: Text('Rolle: Org‑Auditor')),
                  DropdownMenuItem(value: 'team_lead', child: Text('Rolle: Team‑Lead')),
                  DropdownMenuItem(value: 'team_member', child: Text('Rolle: Team‑Member')),
                ],
                onChanged: (v) {
                  // Speichern wir temporär in qrData? Besser: merken im Tooltip durch appSettingsProvider.userRole
                  // Hier minimal: Writing choice to app settings for reuse
                  final s = ref.read(appSettingsProvider);
                  ref.read(settingsServiceProvider).saveSettings(s.copyWith(userRole: v ?? s.userRole, updatedAt: DateTime.now()));
                },
                decoration: const InputDecoration(labelText: 'Rolle (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: teamsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teams (CSV, optional)',
                  hintText: 'z. B. tbew,xyz',
                ),
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              if (isLoading) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Org: ${ref.read(appSettingsProvider).organizationId ?? 'default'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              if (errorText != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorText!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (qrData != null) ...[
                if (qrPng != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(qrPng!, width: 240, height: 240, filterQuality: FilterQuality.none),
                      const SizedBox(height: 8),
                      const Text('Mit der Mobil‑App scannen (Team‑Key Provisionierung).'),
                    ],
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 8),
                      LinearProgressIndicator(minHeight: 2),
                      SizedBox(height: 8),
                      Text('Erzeuge QR‑Grafik…'),
                    ],
                  ),
                const SizedBox(height: 8),
                if (keyPreview != null)
                  SelectableText('Key (Base64, gekürzt): ${keyPreview!}'),
              ] else ...[
                const Text('Noch kein QR erzeugt. Team‑ID eingeben und eine Aktion wählen.'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
            if ((qrData == null) && (ctrl.text.trim().isNotEmpty))
              OutlinedButton(
                onPressed: () async {
                  final teamId = ctrl.text.trim();
                  if (teamId.isEmpty) {
                    setState(() => errorText = 'Bitte Team‑ID eingeben.');
                    return;
                  }
                  try {
                    debugPrint('[QR] recreate: start');
                    final sw = Stopwatch()..start();
                    setState(() { isLoading = true; errorText = null; });
                    final crypto = ref.read(cryptoStorageProvider);
                    final client = ref.read(hidriveClientProvider);
                    final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                    final svc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                    final b64 = await svc.recreateTeamKey(teamId);
                    if (b64 == null || b64.isEmpty) {
                      setState(() { errorText = 'Team‑Key konnte nicht neu erzeugt werden.'; isLoading = false; });
                      return;
                    }
                    final payload = <String, dynamic>{
                      'type': 'egh-team-key',
                      'org': org,
                      'team': teamId,
                      'key': b64,
                      'ts': DateTime.now().toUtc().toIso8601String(),
                    };
                    final teamsCsv = teamsCtrl.text.trim();
                    if (teamsCsv.isNotEmpty) {
                      payload['teams'] = teamsCsv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    }
                    setState(() {
                      qrData = jsonEncode(payload);
                      keyPreview = b64.length > 64 ? '${b64.substring(0,64)}...' : b64;
                      errorText = null;
                      isLoading = false;
                      qrPng = null;
                    });
                    try {
                      final painter = QrPainter(
                        data: qrData!,
                        version: QrVersions.auto,
                        gapless: false,
                      );
                      final data = await painter.toImageData(280, format: ui.ImageByteFormat.png);
                      if (data != null) {
                        setState(() { qrPng = data.buffer.asUint8List(); });
                        debugPrint('[QR] png generated: ${qrPng!.lengthInBytes} bytes');
                      }
                    } catch (e) {
                      debugPrint('[QR] png generation failed: $e');
                    }
                    debugPrint('[QR] recreate: success in ${sw.elapsedMilliseconds}ms');
                  } catch (e) {
                    setState(() { errorText = 'Fehler: $e'; isLoading = false; });
                    debugPrint('[QR] recreate: Fehler: $e');
                  }
                },
                child: const Text('Neu erzeugen (überschreiben)'),
              ),
            FilledButton(
              onPressed: () async {
                try {
                  debugPrint('[QR] anzeigen: start');
                  final sw = Stopwatch()..start();
                  final teamId = ctrl.text.trim();
                  if (teamId.isEmpty) {
                    setState(() => errorText = 'Bitte Team‑ID eingeben.');
                    return;
                  }
                  setState(() { isLoading = true; errorText = null; });
                  final crypto = ref.read(cryptoStorageProvider);
                  final client = ref.read(hidriveClientProvider);
                  final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                  final svc = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                  final b64 = await svc.fetchTeamKeyBase64(teamId);
                  if (b64 == null) {
                    // versuche anzulegen
                    debugPrint('[QR] anzeigen: kein Key, ensureTeamKey…');
                    final ok = await svc.ensureTeamKey(teamId);
                    if (!ok) {
                      setState(() { errorText = 'Team‑Key existiert nicht und konnte nicht erzeugt werden.'; isLoading = false; });
                      return;
                    }
                  }
                  final keyB64Local = (b64 ?? await svc.fetchTeamKeyBase64(teamId)) ?? '';
                  if (keyB64Local.isEmpty) {
                    setState(() { errorText = 'Team‑Key konnte nicht geladen werden. Mögliche Ursache: geänderte Passphrase/MEK. Verwenden Sie „Neu erzeugen (überschreiben)“.'; isLoading = false; });
                    return;
                  }
                  final payload = <String, dynamic>{
                    'type': 'egh-team-key',
                    'org': org,
                    'team': teamId,
                    'key': keyB64Local,
                    'ts': DateTime.now().toUtc().toIso8601String(),
                  };
                  final teamsCsv2 = teamsCtrl.text.trim();
                  if (teamsCsv2.isNotEmpty) {
                    payload['teams'] = teamsCsv2.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  }
                  final role = ref.read(appSettingsProvider).userRole;
                  if (role != null && role.isNotEmpty) payload['role'] = role;
                  setState(() {
                    qrData = jsonEncode(payload);
                    keyPreview = keyB64Local.length > 64 ? '${keyB64Local.substring(0,64)}...' : keyB64Local;
                    errorText = null;
                    isLoading = false;
                    qrPng = null;
                  });
                  try {
                    final painter = QrPainter(
                      data: qrData!,
                      version: QrVersions.auto,
                      gapless: false,
                    );
                    final data = await painter.toImageData(280, format: ui.ImageByteFormat.png);
                    if (data != null) {
                      setState(() { qrPng = data.buffer.asUint8List(); });
                      debugPrint('[QR] png generated: ${qrPng!.lengthInBytes} bytes');
                    }
                  } catch (e) {
                    debugPrint('[QR] png generation failed: $e');
                  }
                  debugPrint('[QR] anzeigen: success in ${sw.elapsedMilliseconds}ms');
                } catch (e) {
                  setState(() { errorText = 'Fehler: $e'; isLoading = false; });
                  debugPrint('[QR] anzeigen: Fehler: $e');
                }
              },
              child: const Text('QR anzeigen'),
            ),
            if (keyPreview != null)
              OutlinedButton(
                onPressed: () async {
                  final text = qrData != null ? (jsonDecode(qrData!) as Map<String,dynamic>)['key'] as String? : null;
                  if (text != null && text.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key in Zwischenablage kopiert')));
                    }
                  }
                },
                child: const Text('Key kopieren'),
              ),
          ],
        ),
      ),
    );
  }

  void _showRewrapDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team‑Records auf Team‑Key rewrap'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Team ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              final teamId = ctrl.text.trim();
              if (teamId.isEmpty) return;
              Navigator.pop(context);
              try {
                final crypto = ref.read(cryptoStorageProvider);
                final client = ref.read(hidriveClientProvider);
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                final admin = TeamKeyAdminService(crypto: crypto, client: client, orgBase: 'eingliederungshilfe/organizations/$org');
                final b64 = await admin.fetchTeamKeyBase64(teamId);
                if (b64 == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Kein Team‑Key vorhanden')));
                  }
                  return;
                }
                final teamKey = base64Decode(b64);
                final rewrap = RewrapService(client: client, crypto: crypto, orgBase: 'eingliederungshilfe/organizations/$org');
                final count = await rewrap.rewrapTeamToTeamKey(teamId, teamKey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $count Dateien rewrapped')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
                }
              }
            },
            child: const Text('Starten'),
          ),
        ],
      ),
    );
  }

}

// QR Anzeige nutzt qr_flutter/QrImageView
