import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/models/notification_log.dart';
import 'package:cardminder/providers/card_provider.dart';
import 'package:cardminder/screens/card_details_screen.dart';
import 'package:cardminder/screens/notification_logs_screen.dart';
import 'package:cardminder/services/notification_log_service.dart';
import 'package:cardminder/theme/app_theme.dart';

class MockNotificationLogNotifier extends NotificationLogNotifier {
  final List<NotificationLog> initialLogs;
  MockNotificationLogNotifier({this.initialLogs = const []});

  @override
  List<NotificationLog> build() {
    return List<NotificationLog>.from(initialLogs);
  }

  @override
  Future<void> markAllAsRead() async {
    state = [
      for (final log in state) log.copyWith(isRead: true),
    ];
  }

  @override
  Future<void> setReadStatus(String id, bool isRead) async {
    state = [
      for (final log in state)
        if (log.id == id) log.copyWith(isRead: isRead) else log,
    ];
  }

  @override
  Future<void> toggleReadStatus(String id) async {
    state = [
      for (final log in state)
        if (log.id == id) log.copyWith(isRead: !log.isRead) else log,
    ];
  }
}

class MockCardNotifier extends CardNotifier {
  final List<CreditCard> initialCards;
  MockCardNotifier({this.initialCards = const []});

  @override
  CardState build() {
    return CardState(cards: initialCards, isLoading: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleCard = CreditCard(
    id: 'card_123',
    cardName: 'Sapphire Preferred',
    lastFourDigits: '4242',
    lastTransactionDate: DateTime.now().subtract(const Duration(days: 60)),
    network: 'Visa',
  );

  final sampleLogs = [
    NotificationLog(
      id: 'log_1',
      cardId: 'card_123',
      cardName: 'Sapphire Preferred',
      message: 'Card inactivity alert: 30 days left',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      daysRemaining: 30,
    ),
    NotificationLog(
      id: 'log_2',
      cardId: 'deleted_card',
      cardName: 'Old Card',
      message: 'Card inactivity alert: 10 days left',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      daysRemaining: 10,
    ),
  ];

  Widget buildTestableScreen({
    List<NotificationLog> logs = const [],
    List<CreditCard> cards = const [],
  }) {
    return ProviderScope(
      overrides: [
        notificationLogNotifierProvider.overrideWith(
          () => MockNotificationLogNotifier(initialLogs: logs),
        ),
        cardNotifierProvider.overrideWith(
          () => MockCardNotifier(initialCards: cards),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NotificationLogsScreen(),
      ),
    );
  }

  group('NotificationLogsScreen Revamp Tests', () {
    testWidgets(
        'Empty state: shows empty illustration and text, no bottom button or Clear All',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(logs: []));
      await tester.pumpAndSettle();

      expect(find.text('Notifications History'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Clear All'), findsNothing);
      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.text('CardMinder will log all notifications here!'),
          findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
        'Sticky bottom button: 56px height and rounded pill shape (radius 28)',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        logs: sampleLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      final bottomBtnFinder = find.byType(ElevatedButton);
      expect(bottomBtnFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(bottomBtnFinder);
      expect(find.text('Mark all as read'), findsOneWidget);

      final shape = button.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, BorderRadius.circular(28));

      final size = tester.getSize(bottomBtnFinder);
      expect(size.height, 56.0);
    });

    testWidgets(
        'Mark all as read button updates all unread logs and becomes disabled',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        logs: sampleLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mark all as read'), findsOneWidget);
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      // Now all logs are read
      expect(find.text('All notifications read'), findsOneWidget);

      final disabledBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(disabledBtn.onPressed, isNull);
    });

    testWidgets(
        'Swipe left marks notification as read', (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        logs: sampleLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      expect(find.text('30 days left until deactivation'), findsOneWidget);
      expect(find.text('30d left'), findsNothing);

      final dismissibleFinder = find.byKey(const Key('dismiss_log_1'));
      expect(dismissibleFinder, findsOneWidget);

      // Swipe from right to left (end-to-start) to mark as read
      await tester.drag(dismissibleFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // After swiping log_1 as read, both logs are now read
      expect(find.text('All notifications read'), findsOneWidget);
    });

    testWidgets(
        'Swipe right marks notification as unread', (tester) async {
      final allReadLogs = [
        sampleLogs[0].copyWith(isRead: true),
        sampleLogs[1].copyWith(isRead: true),
      ];

      await tester.pumpWidget(buildTestableScreen(
        logs: allReadLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      expect(find.text('All notifications read'), findsOneWidget);

      final dismissibleFinder = find.byKey(const Key('dismiss_log_2'));
      // Swipe from left to right (start-to-end) to mark as unread
      await tester.drag(dismissibleFinder, const Offset(500, 0));
      await tester.pumpAndSettle();

      // Now log_2 is unread, bottom button changes back to "Mark all as read"
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets(
        'Tap notification navigates to CardDetailsScreen when card exists',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        logs: sampleLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      // Tap on the first notification (Sapphire Preferred)
      await tester.tap(find.text('Sapphire Preferred'));
      await tester.pumpAndSettle();

      // Should have pushed CardDetailsScreen
      expect(find.byType(CardDetailsScreen), findsOneWidget);

      // Pop back to notification history screen
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Notification log_1 was marked as read, so now all notifications are read
      expect(find.text('All notifications read'), findsOneWidget);
    });

    testWidgets(
        'Tap notification shows error SnackBar when card no longer exists',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        logs: sampleLogs,
        cards: [sampleCard],
      ));
      await tester.pumpAndSettle();

      // Tap on the second notification (deleted card)
      await tester.tap(find.text('Old Card'));
      await tester.pumpAndSettle();

      expect(find.text('Card Not Found'), findsOneWidget);
      expect(find.text('This card was deleted or no longer exists.'),
          findsOneWidget);
    });
  });

  group('formatNotificationTimestamp Tests', () {
    final fixedNow = DateTime(2026, 9, 25, 15, 30); // Sep 25, 2026 at 3:30 PM

    test('Today: 2 hours ago shows "Today at 1:30 PM (2h ago)"', () {
      final ts = DateTime(2026, 9, 25, 13, 30);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Today at 1:30 PM (2h ago)');
    });

    test('Today: 15 minutes ago shows "Today at 3:15 PM (15m ago)"', () {
      final ts = DateTime(2026, 9, 25, 15, 15);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Today at 3:15 PM (15m ago)');
    });

    test('Today: less than a minute ago shows "Today at 3:29 PM (just now)"', () {
      final ts = DateTime(2026, 9, 25, 15, 29, 45);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Today at 3:29 PM (just now)');
    });

    test('Yesterday shows "Yesterday at 3:30 PM"', () {
      final ts = DateTime(2026, 9, 24, 15, 30);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Yesterday at 3:30 PM');
    });

    test('Earlier this year shows "Sep 20 at 3:30 PM"', () {
      final ts = DateTime(2026, 9, 20, 15, 30);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Sep 20 at 3:30 PM');
    });

    test('Earlier year shows "Sep 25, 2025 at 3:30 PM"', () {
      final ts = DateTime(2025, 9, 25, 15, 30);
      expect(formatNotificationTimestamp(ts, fixedNow),
          'Sep 25, 2025 at 3:30 PM');
    });
  });
}
