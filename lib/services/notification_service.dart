import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
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
      icon: 'ic_notification',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 2));
      final timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        final dynamic timeZoneInfo = await FlutterTimezone.getLocalTimezone()
            .timeout(const Duration(seconds: 2));
        final String timeZoneName = timeZoneInfo.toString();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {}
    }

    void onNotificationResponse(NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.startsWith('install_apk:')) {
        final filePath = payload.substring('install_apk:'.length);
        if (filePath.isNotEmpty) {
          GithubReleaseApkUpdater().installApk(filePath);
        }
      }
    }

    try {
      const androidSettings = AndroidInitializationSettings('ic_notification');
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
        onDidReceiveNotificationResponse: onNotificationResponse,
      );
    } catch (e) {
      debugPrint('Notification init with ic_notification failed: $e. Falling back to @mipmap/ic_launcher');
      try {
        const androidFallback =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const fallbackSettings = InitializationSettings(
          android: androidFallback,
          iOS: iosSettings,
        );
        await _notificationsPlugin.initialize(
          settings: fallbackSettings,
          onDidReceiveNotificationResponse: onNotificationResponse,
        );
      } catch (_) {}
    }
  }

  static const int updateNotificationId = 77777;

  static Future<void> showDownloadProgressNotification({
    required String versionName,
    required int progressPercent,
    required String progressText,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'cardminder_updates',
      'App Updates',
      channelDescription: 'Notifications for app updates and downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      onlyAlertOnce: true,
      icon: 'ic_notification',
    );

    await _notificationsPlugin.show(
      id: updateNotificationId,
      title: 'Downloading CardMinder v$versionName',
      body: progressText,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showDownloadCompleteNotification({
    required String versionName,
    required String filePath,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cardminder_updates',
      'App Updates',
      channelDescription: 'Notifications for app updates and downloads',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
      ongoing: false,
      autoCancel: true,
      icon: 'ic_notification',
    );

    await _notificationsPlugin.show(
      id: updateNotificationId,
      title: 'Update Ready to Install',
      body: 'CardMinder v$versionName is downloaded. Tap to install.',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'install_apk:$filePath',
    );
  }

  static Future<void> cancelUpdateNotification() async {
    await _notificationsPlugin.cancel(id: updateNotificationId);
  }

  static Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (_) {}
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

      final reminderDate =
          deactivationDate.subtract(Duration(days: daysBefore));
      // Schedule for 9:00 AM on the reminder day
      final morningReminder = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9,
        0,
      );

      final targetDate =
          morningReminder.isAfter(now) ? morningReminder : reminderDate;

      if (targetDate.isAfter(now)) {
        final scheduledTZDate = tz.TZDateTime.from(targetDate, tz.local);

        final cardDigitsInfo =
            card.lastFourDigits != null && card.lastFourDigits!.isNotEmpty
                ? ' (•• ${card.lastFourDigits})'
                : '';

        try {
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '💳 Card Transaction Reminder',
            body:
                '${card.cardName}$cardDigitsInfo needs a transaction in $daysBefore day(s) to avoid deactivation!',
            scheduledDate: scheduledTZDate,
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '💳 Card Transaction Reminder',
            body:
                '${card.cardName}$cardDigitsInfo needs a transaction in $daysBefore day(s) to avoid deactivation!',
            scheduledDate: scheduledTZDate,
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
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
    try {
      await _notificationsPlugin.zonedSchedule(
        id: _debugScheduledId,
        title: '💳 CardMinder Scheduled Test',
        body: 'This test notification was scheduled 1 minute ago.',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id: _debugScheduledId,
        title: '💳 CardMinder Scheduled Test',
        body: 'This test notification was scheduled 1 minute ago.',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    return DateTime.now().add(const Duration(minutes: 1));
  }

  /// Debug-only: list notifications the OS has queued.
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    assert(kDebugMode);
    return _notificationsPlugin.pendingNotificationRequests();
  }
}
