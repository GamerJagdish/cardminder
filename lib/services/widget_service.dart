import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import '../models/app_settings.dart';
import '../models/credit_card.dart';
import '../theme/app_theme.dart';

class WidgetService {
  static const String appGroupId = 'group.com.gamerjagdish.cardminder';
  static const String androidWidgetName = 'CardMinderWidgetProvider';

  static Future<void> updateHomeWidget(
    List<CreditCard> cards, {
    AppSettings? settings,
  }) async {
    try {
      AppSettings config = settings ?? AppSettings();
      if (settings == null) {
        try {
          if (Hive.isBoxOpen('settings_box')) {
            final raw = Hive.box<String>('settings_box').get('user_settings');
            if (raw != null) {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              config = AppSettings.fromJson(map);
            }
          }
        } catch (_) {}
      }

      await HomeWidget.setAppGroupId(appGroupId);

      // Filter cards
      List<CreditCard> filtered = cards.where((card) {
        switch (config.widgetFilter) {
          case 'action_needed':
            return card.daysRemaining <= 30;
          case 'warning_and_urgent':
            return card.daysRemaining <= 90;
          case 'all':
          default:
            return true;
        }
      }).toList();

      // Sort cards by urgency (fewest days left first), then tie-break by name
      filtered.sort((a, b) {
        final cmp = a.daysRemaining.compareTo(b.daysRemaining);
        if (cmp != 0) return cmp;
        return a.cardName.toLowerCase().compareTo(b.cardName.toLowerCase());
      });

      // Limit max cards
      if (filtered.length > config.widgetMaxCards) {
        filtered = filtered.sublist(0, config.widgetMaxCards);
      }

      // Serialize card list items for Android RemoteViews with colors, network, and status
      final List<Map<String, dynamic>> cardItems = filtered.map((c) {
        final colors = AppTheme.getCardColors(c.colorIndex);
        final primaryColor = colors.first;
        final hexColor =
            '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

        return {
          'name': c.cardName,
          'digits': c.lastFourDigits ?? '0000',
          'days': c.daysRemaining,
          'status': c.status.label,
          'urgent': c.daysRemaining <= 30,
          'color': hexColor,
          'network': c.network,
          'bank': c.bankName ?? '',
        };
      }).toList();

      final jsonString = jsonEncode(cardItems);

      await HomeWidget.saveWidgetData<String>('widget_cards_json', jsonString);
      await HomeWidget.saveWidgetData<int>('total_cards', cards.length);
      await HomeWidget.saveWidgetData<int>('widget_cards_count', filtered.length);
      await HomeWidget.saveWidgetData<String>('theme_mode', config.themeMode);

      // Update most urgent card summary info as fallback
      if (filtered.isNotEmpty) {
        final mostUrgent = filtered.first;
        await HomeWidget.saveWidgetData<String>('urgent_card_name', mostUrgent.cardName);
        await HomeWidget.saveWidgetData<String>(
          'urgent_card_digits',
          mostUrgent.lastFourDigits != null ? '•••• ${mostUrgent.lastFourDigits}' : '',
        );
        await HomeWidget.saveWidgetData<int>('urgent_card_days', mostUrgent.daysRemaining);
      } else {
        await HomeWidget.saveWidgetData<String>('urgent_card_name', 'No Cards Tracked');
        await HomeWidget.saveWidgetData<String>('urgent_card_digits', '');
        await HomeWidget.saveWidgetData<int>('urgent_card_days', -1);
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: 'com.gamerjagdish.cardminder.$androidWidgetName',
      );
    } catch (e) {
      // Ignore widget failure
    }
  }
}
