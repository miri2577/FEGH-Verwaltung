import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'shared/themes/app_theme.dart';
import 'widgets/layouts/main_layout.dart';
import 'providers/settings_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/notification_provider.dart';
import 'services/local_storage_service.dart';
import 'services/crypto_storage.dart';
import 'services/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting
  await initializeDateFormatting('de_DE');

  // Initialize core services
  final localStorageService = LocalStorageService();
  final cryptoStorage = CryptoStorage();

  try {
    await localStorageService.initialize();
    await cryptoStorage.initialize();
    print('✅ Core services initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize core services: $e');
  }

  // Desktop Window Configuration (nicht im Web)
  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1400, 900),
      minimumSize: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      title: 'FEGH-Verwaltung',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
        cryptoStorageProvider.overrideWithValue(cryptoStorage),
      ],
      child: const PersonalverwaltungApp(),
    ),
  );
}

class PersonalverwaltungApp extends ConsumerWidget {
  const PersonalverwaltungApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    final ui = settings.uiCustomization;

    return MaterialApp(
      title: 'FEGH-Verwaltung',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.createLightTheme(ui: ui),
      darkTheme: AppTheme.createDarkTheme(ui: ui),
      themeMode: settings.enableDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _DemoWrapper(),
    );
  }
}

class _DemoWrapper extends ConsumerStatefulWidget {
  const _DemoWrapper();

  @override
  ConsumerState<_DemoWrapper> createState() => _DemoWrapperState();
}

class _DemoWrapperState extends ConsumerState<_DemoWrapper> {
  bool _demoShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_demoShown) {
        _demoShown = true;
        _showDemoDialog();
      }
    });
  }

  void _showDemoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 48, color: Colors.orange),
        title: const Text('Demo-Modus'),
        content: const Text(
          'Willkommen in der FEGH-Verwaltung Demo.\n\n'
          'Bitte geben Sie keine echten personenbezogenen Daten ein. '
          'Die Daten werden nur lokal gespeichert und '
          'können jederzeit verloren gehen.\n\n'
          'Diese App befindet sich in einer frühen Beta-Phase. '
          'Es werden Demo-Daten mit fiktiven Mitarbeitern und Klienten geladen.',
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DemoDataService.loadDemoData(ref);
            },
            child: const Text('Verstanden – Demo starten'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const MainLayout();
  }
}
