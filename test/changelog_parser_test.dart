import 'package:cardminder/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangelogParser', () {
    test('parses conventional commit messages into correct categories', () {
      const raw = '''## What's Changed
* feat: add home screen widget by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/1111111
* fix: resolve crash on Android 14 by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/2222222
* chore: update pubspec dependencies by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/3333333
* refactor: clean up widget service by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/4444444

**Full Changelog**: https://github.com/GamerJagdish/cardminder/compare/v1.0.0...v1.0.1''';

      final result = ChangelogParser.parse(raw);

      expect(result.categories.containsKey('feature:'), isTrue);
      expect(result.categories['feature:'], ['Add home screen widget']);

      expect(result.categories.containsKey('fix:'), isTrue);
      expect(result.categories['fix:'], ['Resolve crash on Android 14']);

      expect(result.categories.containsKey('chore:'), isTrue);
      expect(result.categories['chore:'], ['Update pubspec dependencies']);

      expect(result.categories.containsKey('refactor:'), isTrue);
      expect(result.categories['refactor:'], ['Clean up widget service']);

      expect(result.categories.containsKey('other:'), isFalse);
    });

    test('attaches indented sub-bullet descriptions to parent commit entry', () {
      const raw = '''## What's Changed
* feat: overhaul widget layout and provider by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/355913f
  * Redesign card_minder_widget layout with branded header
  * Render authentic miniature credit card bitmaps
* chore: update project metadata by @GamerJagdish in https://github.com/GamerJagdish/cardminder/commit/17aa0aa
  * Add F-Droid metadata to gitignore''';

      final result = ChangelogParser.parse(raw);

      expect(result.categories['feature:']!.length, 1);
      expect(
        result.categories['feature:']!.first,
        'Overhaul widget layout and provider\n   • Redesign card_minder_widget layout with branded header\n   • Render authentic miniature credit card bitmaps',
      );

      expect(result.categories['chore:']!.length, 1);
      expect(
        result.categories['chore:']!.first,
        'Update project metadata\n   • Add F-Droid metadata to gitignore',
      );

      expect(result.categories.containsKey('other:'), isFalse);
    });

    test('attaches unindented description bullets from older release bodies to parent commit', () {
      const raw = '''## What's Changed in 1.2.5
* **feat: overhaul widget layout and provider with mini cards and urgency pills**
- Redesign card_minder_widget layout with branded header
- Render authentic miniature credit card bitmaps
* **chore: add F-Droid metadata to .gitignore**
- Ignore com.gamerjagdish.cardminder.yml in git''';

      final result = ChangelogParser.parse(raw);

      expect(result.categories['feature:']!.length, 1);
      expect(
        result.categories['feature:']!.first,
        'Overhaul widget layout and provider with mini cards and urgency pills\n   • Redesign card_minder_widget layout with branded header\n   • Render authentic miniature credit card bitmaps',
      );

      expect(result.categories['chore:']!.length, 1);
      expect(
        result.categories['chore:']!.first,
        'Add F-Droid metadata to .gitignore\n   • Ignore com.gamerjagdish.cardminder.yml in git',
      );

      expect(result.categories.containsKey('other:'), isFalse);
    });
  });
}
