import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_log_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await StorageService.init();
  await SettingsNotifier.init();
  await NotificationLogService.init();
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(
    const ProviderScope(
      child: CardMinderApp(),
    ),
  );
}

class CardMinderApp extends ConsumerWidget {
  const CardMinderApp({super.key});

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeStr = ref.watch(
      settingsNotifierProvider.select((s) => s.themeMode),
    );

    return MaterialApp(
      title: 'CardMinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _parseThemeMode(themeModeStr),
      home: const HomeScreen(),
    );
  }
}
