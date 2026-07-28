import 'package:home_widget/home_widget.dart';
import '../models/credit_card.dart';

class WidgetService {
  static const String appGroupId = 'group.com.gamerjagdish.cardminder';
  static const String androidWidgetName = 'CardMinderWidgetProvider';

  static Future<void> updateHomeWidget(List<CreditCard> cards) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      if (cards.isEmpty) {
        await HomeWidget.saveWidgetData<String>('urgent_card_name', 'No Cards');
        await HomeWidget.saveWidgetData<String>('urgent_card_digits', '');
        await HomeWidget.saveWidgetData<int>('urgent_card_days', 0);
        await HomeWidget.saveWidgetData<int>('total_cards', 0);
        await HomeWidget.saveWidgetData<int>('urgent_cards_count', 0);
      } else {
        // Sort to find most urgent card
        final sorted = List<CreditCard>.from(cards)
          ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        final mostUrgent = sorted.first;

        final urgentCount = cards.where((c) => c.daysRemaining <= 30).length;

        await HomeWidget.saveWidgetData<String>(
          'urgent_card_name',
          mostUrgent.cardName,
        );
        await HomeWidget.saveWidgetData<String>(
          'urgent_card_digits',
          mostUrgent.lastFourDigits != null && mostUrgent.lastFourDigits!.isNotEmpty
              ? '•••• ${mostUrgent.lastFourDigits}'
              : '',
        );
        await HomeWidget.saveWidgetData<int>(
          'urgent_card_days',
          mostUrgent.daysRemaining,
        );
        await HomeWidget.saveWidgetData<int>('total_cards', cards.length);
        await HomeWidget.saveWidgetData<int>('urgent_cards_count', urgentCount);
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: 'com.gamerjagdish.cardminder.$androidWidgetName',
      );
    } catch (e) {
      // Widget update failed or non-supported platform
    }
  }
}
