import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/credit_card.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _boxName = 'settings_box';
  static const String _key = 'user_settings';

  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  void _loadSettings() {
    final jsonStr = _box.get(_key);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = AppSettings.fromJson(map);
      } catch (e) {
        // Fallback default settings
      }
    }
  }

  Future<void> updateSettings(AppSettings newSettings, List<CreditCard> cards) async {
    state = newSettings;
    await _box.put(_key, jsonEncode(newSettings.toJson()));
    _syncServices(cards);
  }

  void _syncServices(List<CreditCard> cards) {
    WidgetService.updateHomeWidget(cards, settings: state);
    NotificationService.syncCardNotifications(cards, settings: state);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
