import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/app_settings.dart';
import '../models/credit_card.dart';

class WidgetService {
  static const String appGroupId = 'group.com.gamerjagdish.cardminder';
  static const String androidWidgetName = 'CardMinderWidgetProvider';

  static Future<void> updateHomeWidget(
    List<CreditCard> cards, {
    AppSettings? settings,
  }) async {
    try {
      final config = settings ?? AppSettings();
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

      // Sort cards
      if (config.widgetSortBy == 'name') {
        filtered.sort((a, b) => a.cardName.compareTo(b.cardName));
      } else {
        // Sort by urgency (fewest days left first)
        filtered.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
      }

      // Limit max cards
      if (filtered.length > config.widgetMaxCards) {
        filtered = filtered.sublist(0, config.widgetMaxCards);
      }

      // Serialize card list items for Android RemoteViews
      final List<Map<String, dynamic>> cardItems = filtered.map((c) {
        return {
          'name': c.cardName,
          'digits': c.lastFourDigits ?? '0000',
          'days': c.daysRemaining,
          'status': c.status.label,
          'urgent': c.daysRemaining <= 30,
        };
      }).toList();

      final jsonString = jsonEncode(cardItems);

      await HomeWidget.saveWidgetData<String>('widget_cards_json', jsonString);
      await HomeWidget.saveWidgetData<int>('total_cards', cards.length);
      await HomeWidget.saveWidgetData<int>('widget_cards_count', filtered.length);

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
