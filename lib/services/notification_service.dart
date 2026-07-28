import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/credit_card.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
  }

  static Future<void> requestPermissions() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> syncCardNotifications(List<CreditCard> cards) async {
    await _notificationsPlugin.cancelAll();

    for (var card in cards) {
      await _scheduleCardReminders(card);
    }
  }

  static Future<void> _scheduleCardReminders(CreditCard card) async {
    final deactivationDate = card.deactivationDate;
    final now = DateTime.now();

    final reminders = [
      {'daysBefore': 30, 'idOffset': 1000},
      {'daysBefore': 7, 'idOffset': 2000},
      {'daysBefore': 1, 'idOffset': 3000},
    ];

    final cardHash = card.id.hashCode.abs() % 100000;

    for (var reminder in reminders) {
      final daysBefore = reminder['daysBefore'] as int;
      final idOffset = reminder['idOffset'] as int;
      final notificationId = cardHash + idOffset;

      final reminderDate = deactivationDate.subtract(Duration(days: daysBefore));

      if (reminderDate.isAfter(now)) {
        final scheduledTZDate = tz.TZDateTime.from(reminderDate, tz.local);

        final cardDigitsInfo = card.lastFourDigits != null && card.lastFourDigits!.isNotEmpty
            ? ' (•• ${card.lastFourDigits})'
            : '';

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: '💳 Card Transaction Reminder',
          body:
              '${card.cardName}$cardDigitsInfo needs a transaction in $daysBefore day(s) to avoid deactivation!',
          scheduledDate: scheduledTZDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'cardminder_channel',
              'Card Expiry Reminders',
              channelDescription:
                  'Notifications for upcoming 365-day card transaction deadlines',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}
