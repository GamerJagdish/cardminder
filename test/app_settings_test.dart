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
      expect(settings.themePreset, equals('classic'));
      expect(settings.animateBackground, isTrue);
      expect(settings.selectedVariants, isEmpty);
    });

    test('AppSettings JSON serialization and deserialization work', () {
      final settings = AppSettings(
        widgetMaxCards: 3,
        widgetFilter: 'action_needed',
        widgetSortBy: 'name',
        notificationsEnabled: false,
        backupPath: '/storage/emulated/0/Download/Backups',
        themePreset: 'aurora_emerald',
        animateBackground: false,
        selectedVariants: {
          'crimson_ruby': 'aurora_emerald',
          'silly_strings': 'silly_strings_cyan',
        },
      );

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.widgetMaxCards, equals(3));
      expect(restored.widgetFilter, equals('action_needed'));
      expect(restored.widgetSortBy, equals('name'));
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.backupPath, equals('/storage/emulated/0/Download/Backups'));
      expect(restored.themePreset, equals('aurora_emerald'));
      expect(restored.animateBackground, isFalse);
      expect(restored.selectedVariants['crimson_ruby'], equals('aurora_emerald'));
      expect(restored.selectedVariants['silly_strings'], equals('silly_strings_cyan'));
    });
  });
}
