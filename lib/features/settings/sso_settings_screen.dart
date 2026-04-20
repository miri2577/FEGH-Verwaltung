import 'dart:convert';

import 'package:fegh_auth_oidc/fegh_auth_oidc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/audit_logger.dart';

/// Konfiguration und Test des OIDC-SSO-Logins.
///
/// Organisationsweit einmal eintragen (Issuer-URL, Client-ID, Scopes).
/// Der Admin kann per "Test-Login" den Flow gegen den konfigurierten
/// Provider ausprobieren; bei Erfolg werden Tokens im sicheren
/// Geraetespeicher abgelegt.
class SsoSettingsScreen extends ConsumerStatefulWidget {
  const SsoSettingsScreen({super.key});

  @override
  ConsumerState<SsoSettingsScreen> createState() => _SsoSettingsScreenState();
}

class _SsoSettingsScreenState extends ConsumerState<SsoSettingsScreen> {
  static const _configKey = 'fegh_oidc_config';

  final _issuer = TextEditingController();
  final _clientId = TextEditingController();
  final _scopes = TextEditingController(text: 'openid profile email');

  OidcLoginResult? _lastLogin;
  bool _busy = false;
  String? _status;
  bool _success = true;

  final _storage = const FlutterSecureStorage();
  final _service = OidcLoginService();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _issuer.dispose();
    _clientId.dispose();
    _scopes.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final raw = await _storage.read(key: _configKey);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cfg = OidcConfig.fromJson(json);
    setState(() {
      _issuer.text = cfg.issuerUrl;
      _clientId.text = cfg.clientId;
      _scopes.text = cfg.scopes.join(' ');
    });
  }

  OidcConfig _buildConfig() {
    return OidcConfig(
      issuerUrl: _issuer.text.trim(),
      clientId: _clientId.text.trim(),
      scopes: _scopes.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _saveConfig() async {
    final cfg = _buildConfig();
    if (cfg.issuerUrl.isEmpty || cfg.clientId.isEmpty) {
      _setStatus('Issuer-URL und Client-ID sind pflicht.', success: false);
      return;
    }
    await _storage.write(key: _configKey, value: jsonEncode(cfg.toJson()));
    _setStatus('Konfiguration gespeichert.', success: true);
    await AuditLogger.log('sso.config.updated', context: {
      'issuer': cfg.issuerUrl,
      'clientId': cfg.clientId,
    });
  }

  Future<void> _testDiscovery() async {
    final cfg = _buildConfig();
    if (cfg.issuerUrl.isEmpty) {
      _setStatus('Issuer-URL eingeben.', success: false);
      return;
    }
    setState(() => _busy = true);
    try {
      final d = await _service.discover(cfg.issuerUrl);
      _setStatus(
          'Discovery OK — authorization_endpoint: ${d.authorizationEndpoint}',
          success: true);
    } catch (e) {
      _setStatus('Discovery fehlgeschlagen: $e', success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testLogin() async {
    final cfg = _buildConfig();
    if (cfg.issuerUrl.isEmpty || cfg.clientId.isEmpty) {
      _setStatus('Issuer-URL und Client-ID erforderlich.', success: false);
      return;
    }
    setState(() {
      _busy = true;
      _lastLogin = null;
    });
    try {
      final result = await _service.login(cfg);
      setState(() => _lastLogin = result);
      _setStatus(
          'Login erfolgreich — Benutzer: ${result.user.feghUserId}',
          success: true);
      await AuditLogger.log('sso.login.success', context: {
        'issuer': cfg.issuerUrl,
        'userId': result.user.feghUserId,
        'sub': result.user.subject,
      });
    } catch (e) {
      _setStatus('Login fehlgeschlagen: $e', success: false);
      await AuditLogger.log('sso.login.failed', context: {
        'issuer': cfg.issuerUrl,
        'error': e.toString(),
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final cfg = _buildConfig();
    await _service.logout(cfg.issuerUrl);
    setState(() => _lastLogin = null);
    _setStatus('Tokens verworfen.', success: true);
    await AuditLogger.log('sso.logout',
        context: {'issuer': cfg.issuerUrl});
  }

  void _setStatus(String msg, {required bool success}) {
    if (!mounted) return;
    setState(() {
      _status = msg;
      _success = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Single Sign-On (OIDC)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provider-Konfiguration',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _issuer,
                      decoration: const InputDecoration(
                        labelText: 'Issuer-URL',
                        helperText:
                            'z. B. https://auth.example.de/realms/fegh',
                        prefixIcon: Icon(Symbols.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientId,
                      decoration: const InputDecoration(
                        labelText: 'Client-ID',
                        prefixIcon: Icon(Symbols.key),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scopes,
                      decoration: const InputDecoration(
                        labelText: 'Scopes (leer getrennt)',
                        prefixIcon: Icon(Symbols.list),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Redirect-URI: http://127.0.0.1:<dynamisch>/callback '
                      '(im Provider unter "Allowed Redirect URIs" als '
                      'http://127.0.0.1/* eintragen oder den Wildcard-Port '
                      'freigeben).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy ? null : _saveConfig,
                          icon: const Icon(Symbols.save),
                          label: const Text('Speichern'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _testDiscovery,
                          icon: const Icon(Symbols.search),
                          label: const Text('Discovery testen'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _testLogin,
                          icon: const Icon(Symbols.login),
                          label: const Text('Test-Login'),
                        ),
                        if (_lastLogin != null)
                          TextButton.icon(
                            onPressed: _busy ? null : _logout,
                            icon: const Icon(Symbols.logout),
                            label: const Text('Logout'),
                          ),
                      ],
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _success
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(_success ? Symbols.check_circle : Symbols.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_status!)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_lastLogin != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Letzter Login', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _row('User-ID (FEGH)', _lastLogin!.user.feghUserId),
                      _row('Subject (OIDC)', _lastLogin!.user.subject),
                      if (_lastLogin!.user.email != null)
                        _row('Email', _lastLogin!.user.email!),
                      if (_lastLogin!.user.name != null)
                        _row('Name', _lastLogin!.user.name!),
                      _row('Token laeuft ab',
                          _lastLogin!.tokens.expiresAt.toLocal().toString()),
                      _row('Scopes',
                          _lastLogin!.tokens.scopes.join(', ')),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 160,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline))),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
