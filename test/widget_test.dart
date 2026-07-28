import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardminder/main.dart';
import 'package:cardminder/services/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('App renders main screen with title', (WidgetTester tester) async {
    Hive.init('./test_hive');
    await StorageService.init();

    await tester.pumpWidget(
      const ProviderScope(
        child: CardMinderApp(),
      ),
    );

    expect(find.text('CardMinder'), findsOneWidget);
  });
}
