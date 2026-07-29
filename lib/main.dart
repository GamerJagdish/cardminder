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

class CardMinderApp extends StatelessWidget {
  const CardMinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardMinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
