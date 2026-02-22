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

  // Desktop Window Configuration
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'Personalverwaltung - Eingliederungshilfe',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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

    return MaterialApp(
      title: 'Personalverwaltung - Eingliederungshilfe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.enableDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainLayout(),
    );
  }
}
