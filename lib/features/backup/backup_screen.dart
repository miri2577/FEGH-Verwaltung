import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../providers/backup_provider.dart';
import '../../services/backup_restore_service.dart';

/// Admin-Screen fuer Backup und Wiederherstellung.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _df = DateFormat('dd.MM.yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(localBackupsProvider);
    final action = ref.watch(backupActionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Wiederherstellung'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(theme),
            const SizedBox(height: 24),
            action.when(
              data: (s) => s.message != null
                  ? _messageCard(theme, s.message!, isError: false)
                  : const SizedBox.shrink(),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _messageCard(theme, e.toString(), isError: true),
            ),
            const SizedBox(height: 16),
            _createSection(theme),
            const SizedBox(height: 32),
            _restoreSection(theme),
            const SizedBox(height: 32),
            _listSection(theme, backups),
          ],
        ),
      ),
    );
  }

  // ── Kopfzeile ────────────────────────────────────────────────────

  Widget _header(ThemeData theme) {
    return Row(
      children: [
        Icon(Symbols.backup, size: 32, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Text('Backup', style: theme.textTheme.headlineLarge),
      ],
    );
  }

  Widget _messageCard(ThemeData theme, String message, {required bool isError}) {
    final color = isError ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final onColor = isError ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(isError ? Symbols.error : Symbols.check_circle, color: onColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: onColor)),
            ),
            IconButton(
              onPressed: () =>
                  ref.read(backupActionProvider.notifier).clearMessage(),
              icon: Icon(Symbols.close, color: onColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Backup erstellen ─────────────────────────────────────────────

  Widget _createSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, Symbols.save, 'Backup erstellen'),
            const SizedBox(height: 8),
            const Text(
              'Sichert alle Nutzdaten (Mitarbeiter, Teams, Klienten, Schichten, '
              'Urlaube, Rechnungen, Zeitnachweise, Benachrichtigungen, '
              'Einstellungen) verschluesselt als .ehbackup-Datei.',
            ),
            const SizedBox(height: 8),
            Text(
              'Zugangsdaten und Master-Encryption-Key werden nicht ins '
              'Backup aufgenommen — sie sind geraetegebunden.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _handleCreate,
              icon: const Icon(Symbols.lock),
              label: const Text('Backup jetzt erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    final password = await _askPassword(
      title: 'Backup-Passwort',
      hint: 'Neues Passwort fuer diese Sicherung',
      requireConfirm: true,
    );
    if (password == null || password.isEmpty) return;
    await ref.read(backupActionProvider.notifier).createBackup(password);
  }

  // ── Wiederherstellung ───────────────────────────────────────────

  Widget _restoreSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, Symbols.restore, 'Backup wiederherstellen'),
            const SizedBox(height: 8),
            const Text(
              'Waehlen Sie eine .ehbackup-Datei aus und geben das dazugehoerige '
              'Passwort ein. Bestehende Daten werden ueberschrieben.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _handleRestoreFromFile,
              icon: const Icon(Symbols.folder_open),
              label: const Text('Datei auswaehlen ...'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRestoreFromFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes ??
        (file.path != null ? File(file.path!).readAsBytesSync() : null);
    if (bytes == null) return;
    await _restoreBytes(Uint8List.fromList(bytes));
  }

  Future<void> _restoreBytes(Uint8List bytes) async {
    final password = await _askPassword(
      title: 'Backup-Passwort',
      hint: 'Passwort der Backup-Datei',
      requireConfirm: false,
    );
    if (password == null || password.isEmpty) return;

    final confirmed = await _confirmDialog(
      title: 'Wiederherstellung starten?',
      message:
          'Bestehende Nutzdaten werden ueberschrieben. Dies kann nicht rueckgaengig '
          'gemacht werden. Moechten Sie fortfahren?',
    );
    if (confirmed != true) return;
    await ref.read(backupActionProvider.notifier).restoreBackup(
          bytes: bytes,
          password: password,
        );
  }

  // ── Liste ───────────────────────────────────────────────────────

  Widget _listSection(ThemeData theme, AsyncValue<List<dynamic>> backups) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, Symbols.history, 'Vorhandene Backups'),
            const SizedBox(height: 12),
            backups.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'Noch keine lokalen Backups vorhanden.',
                    style: TextStyle(color: theme.colorScheme.outline),
                  );
                }
                return Column(
                  children: list.map((b) => _backupTile(theme, b)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('Fehler: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backupTile(ThemeData theme, dynamic info) {
    // info ist BackupInfo aus fegh_backup; mit dynamic vermeiden wir
    // hier den Import-Reihenfolge-Zwang.
    final filename = info.filename as String;
    final createdAt = info.createdAt as DateTime;
    final size = info.formattedFileSize as String;
    return ListTile(
      leading: Icon(Symbols.folder_zip,
          color: theme.colorScheme.primary),
      title: Text(filename),
      subtitle: Text('${_df.format(createdAt)}  |  $size'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Wiederherstellen',
            icon: const Icon(Symbols.restore),
            onPressed: () => _restoreFromLocal(filename),
          ),
          IconButton(
            tooltip: 'Loeschen',
            icon: const Icon(Symbols.delete),
            onPressed: () => _deleteLocal(filename),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromLocal(String filename) async {
    final dir = await BackupRestoreService.backupDirectory();
    final file = File('${dir.path}/$filename');
    if (!file.existsSync()) return;
    await _restoreBytes(file.readAsBytesSync());
  }

  Future<void> _deleteLocal(String filename) async {
    final confirmed = await _confirmDialog(
      title: 'Backup loeschen?',
      message: '"$filename" wird unwiderruflich entfernt.',
    );
    if (confirmed != true) return;
    await ref.read(backupActionProvider.notifier).deleteBackup(filename);
  }

  // ── Hilfen ──────────────────────────────────────────────────────

  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Future<String?> _askPassword({
    required String title,
    required String hint,
    required bool requireConfirm,
  }) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    bool obscure = true;
    return showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: hint,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Symbols.visibility : Symbols.visibility_off),
                    onPressed: () => setDialog(() => obscure = !obscure),
                  ),
                ),
              ),
              if (requireConfirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: c2,
                  obscureText: obscure,
                  decoration: const InputDecoration(labelText: 'Wiederholung'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (requireConfirm && c1.text != c2.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Passwoerter stimmen nicht ueberein'),
                  ));
                  return;
                }
                Navigator.of(ctx).pop(c1.text);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }
}
