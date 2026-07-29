import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_settings.dart';
import '../models/credit_card.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _debugImmediateId = 99999;
  static const int _debugScheduledId = 99998;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'cardminder_channel',
      'Card Expiry Reminders',
      channelDescription:
          'Notifications for upcoming 365-day card transaction deadlines',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

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

  static Future<void> syncCardNotifications(
    List<CreditCard> cards, {
    AppSettings? settings,
  }) async {
    await _notificationsPlugin.cancelAll();

    final config = settings ?? AppSettings();
    if (!config.notificationsEnabled) return;

    for (var card in cards) {
      await _scheduleCardReminders(card, config);
    }
  }

  static Future<void> _scheduleCardReminders(
      CreditCard card, AppSettings settings) async {
    final deactivationDate = card.deactivationDate;
    final now = DateTime.now();

    final reminders = <Map<String, dynamic>>[];

    if (settings.notify30Days) {
      reminders.add({'daysBefore': 30, 'idOffset': 1000});
    }
    if (settings.notify14Days) {
      reminders.add({'daysBefore': 14, 'idOffset': 1500});
    }
    if (settings.notify7Days) {
      reminders.add({'daysBefore': 7, 'idOffset': 2000});
    }
    if (settings.notify1Day) {
      reminders.add({'daysBefore': 1, 'idOffset': 3000});
    }

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
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  /// Debug-only: fire a notification immediately to verify permissions/channel.
  static Future<void> showTestNotification() async {
    assert(kDebugMode);
    await _notificationsPlugin.show(
      id: _debugImmediateId,
      title: '💳 CardMinder Test',
      body: 'If you see this, notifications are working.',
      notificationDetails: _notificationDetails,
    );
  }

  /// Debug-only: schedule a notification ~1 minute from now.
  static Future<DateTime> scheduleTestNotificationInOneMinute() async {
    assert(kDebugMode);
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    await _notificationsPlugin.zonedSchedule(
      id: _debugScheduledId,
      title: '💳 CardMinder Scheduled Test',
      body: 'This test notification was scheduled 1 minute ago.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    return scheduledDate.toLocal();
  }

  /// Debug-only: list notifications the OS has queued.
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    assert(kDebugMode);
    return _notificationsPlugin.pendingNotificationRequests();
  }
}
