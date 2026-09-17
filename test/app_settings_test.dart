import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/app_settings.dart';

void main() {
  group('AppSettings Tests', () {
    test('Default AppSettings values are correct', () {
      final settings = AppSettings();

      expect(settings.widgetMaxCards, equals(100));
      expect(settings.widgetFilter, equals('all'));
      expect(settings.widgetSortBy, equals('urgency'));
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.notify30Days, isTrue);
      expect(settings.notify14Days, isTrue);
      expect(settings.backupPath, isEmpty);
    });

    test('AppSettings JSON serialization and deserialization work', () {
      final settings = AppSettings(
        widgetMaxCards: 3,
        widgetFilter: 'action_needed',
        widgetSortBy: 'name',
        notificationsEnabled: false,
        backupPath: '/storage/emulated/0/Download/Backups',
      );

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.widgetMaxCards, equals(3));
      expect(restored.widgetFilter, equals('action_needed'));
      expect(restored.widgetSortBy, equals('name'));
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.backupPath, equals('/storage/emulated/0/Download/Backups'));
    });
  });
}
