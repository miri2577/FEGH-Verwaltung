import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../features/teams/teams_screen.dart';
import '../../features/clients/clients_screen.dart';
import '../../features/shifts/shifts_screen.dart';
import '../../features/timesheets/timesheets_screen.dart';
import '../../features/vacation/vacation_screen.dart';
import '../../features/icf/icf_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/capacity/capacity_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/widgets/notification_bell.dart';
import '../../models/ui_customization.dart';
import '../../providers/hidrive_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/org_admin_sync_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Symbols.business,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Personalverwaltung',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            Text(
              'Eingliederungshilfe',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const NotificationBell(
            iconColor: Colors.white,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Symbols.sync),
            onPressed: () async {
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('🔄 Admin‑Sync gestartet…')));
              try {
                final client = ref.read(hidriveClientProvider);
                final org = ref.read(appSettingsProvider).organizationId ?? 'default';
                // Ordner-Struktur sicherstellen
                final setupOk = await OrgAdminSyncService(client: client, orgId: org).run();
                // Pull → Push (Beispiel: Mitarbeiter)
                await ref.read(employeesProvider.notifier).syncFromCloud();
                await ref.read(employeesProvider.notifier).syncToCloud();
                messenger.clearSnackBars();
                messenger.showSnackBar(SnackBar(content: Text(setupOk ? '✅ Admin‑Sync abgeschlossen' : '⚠️ Admin‑Ordner teilweise fehlgeschlagen')));
              } catch (e) {
                messenger.clearSnackBars();
                messenger.showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
              }
            },
            tooltip: 'Daten synchronisieren',
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _tabController.animateTo(10);
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Symbols.settings),
                  title: Text('Einstellungen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Symbols.info),
                  title: Text('Über'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: _buildTabs(ref.watch(appSettingsProvider).uiCustomization.tabDisplayMode),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardScreen(),
          EmployeesScreen(),
          TeamsScreen(),
          ClientsScreen(),
          ShiftsScreen(),
          TimesheetsScreen(),
          VacationScreen(),
          ICFScreen(),
          ReportsScreen(),
          CapacityScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildStatusBar(),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Symbols.circle,
              size: 12,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Verbunden',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 24),
            Icon(
              Symbols.schedule,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              _lastSyncDisplay(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              '${_getTabName(_currentIndex)} aktiv',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 24),
            Text(
              'v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSyncDisplay() {
    try {
      final settings = ref.watch(appSettingsProvider);
      final syncStr = settings.lastSyncTime;
      if (syncStr == null || syncStr.isEmpty) return 'Noch nicht synchronisiert';
      final syncTime = DateTime.tryParse(syncStr);
      if (syncTime == null) return 'Noch nicht synchronisiert';
      final diff = DateTime.now().difference(syncTime);
      if (diff.inMinutes < 1) return 'Letzte Sync: gerade';
      if (diff.inMinutes < 60) return 'Letzte Sync: vor ${diff.inMinutes} Min.';
      if (diff.inHours < 24) return 'Letzte Sync: vor ${diff.inHours} Std.';
      return 'Letzte Sync: vor ${diff.inDays} Tag${diff.inDays > 1 ? 'en' : ''}';
    } catch (_) {
      return 'Noch nicht synchronisiert';
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Mitarbeiter';
      case 2:
        return 'Teams';
      case 3:
        return 'Klienten';
      case 4:
        return 'Schichten';
      case 5:
        return 'Zeiten';
      case 6:
        return 'Urlaub';
      case 7:
        return 'ICF/TIB';
      case 8:
        return 'Berichte';
      case 9:
        return 'Kapazität';
      case 10:
        return 'Einstellungen';
      default:
        return '';
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Personalverwaltung',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Eingliederungshilfe Enterprise',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Enterprise Personalverwaltung für Eingliederungshilfe-Einrichtungen. '
          'Entwickelt mit Flutter für maximale Performance und Benutzerfreundlichkeit.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• ICF-Klassifikation nach SGB IX'),
        const Text('• Berliner TIB-System Integration'),
        const Text('• Professionelle PDF-Berichte'),
        const Text('• Cloud-Synchronisation'),
        const Text('• DSGVO-konforme Datenhaltung'),
      ],
    );
  }

  List<Tab> _buildTabs(TabDisplayMode mode) {
    const tabData = <({IconData icon, String label})>[
      (icon: Symbols.dashboard, label: 'Dashboard'),
      (icon: Symbols.group, label: 'Mitarbeiter'),
      (icon: Symbols.corporate_fare, label: 'Teams'),
      (icon: Symbols.people, label: 'Klienten'),
      (icon: Symbols.schedule, label: 'Schichten'),
      (icon: Symbols.assignment, label: 'Zeiten'),
      (icon: Symbols.beach_access, label: 'Urlaub'),
      (icon: Symbols.health_and_safety, label: 'ICF/TIB'),
      (icon: Symbols.assessment, label: 'Berichte'),
      (icon: Symbols.analytics, label: 'Kapazitaet'),
      (icon: Symbols.settings, label: 'Einstellungen'),
    ];

    return tabData.map((t) {
      switch (mode) {
        case TabDisplayMode.iconAndText:
          return Tab(icon: Icon(t.icon, size: 20), text: t.label);
        case TabDisplayMode.iconOnly:
          return Tab(icon: Icon(t.icon, size: 20));
        case TabDisplayMode.textOnly:
          return Tab(text: t.label);
      }
    }).toList();
  }
}
