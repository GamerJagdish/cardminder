import '../models/categorized_changelog.dart';

/// Parses raw markdown GitHub release bodies into structured, categorized commit lists.
class ChangelogParser {
  static CategorizedChangelog parse(String raw) {
    if (raw.trim().isEmpty) return CategorizedChangelog({});

    final lines = raw.split('\n');
    final Map<String, List<String>> groups = {
      'refactor:': [],
      'feature:': [],
      'fix:': [],
      'chore:': [],
      'other:': [],
    };

    String? currentCategory;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final isIndented = line.startsWith('  ') || line.startsWith('\t');
      var trimmed = line.trim();

      // Ignore markdown headers
      if (trimmed.startsWith('#')) continue;

      // Ignore full changelog comparisons / links
      if (trimmed.toLowerCase().contains('full changelog')) continue;
      if (trimmed.toLowerCase().contains('compare/')) continue;
      if (trimmed.toLowerCase().startsWith('see full')) continue;

      // Check if this line looks like a commit header (contains author / commit URL)
      final hasCommitMeta =
          RegExp(r'\s+by\s+@\S+', caseSensitive: false).hasMatch(trimmed) ||
              RegExp(r'\s+in\s+https?://\S+', caseSensitive: false)
                  .hasMatch(trimmed);

      // Remove bullet list characters (*, -, +, 1., 2.)
      trimmed = trimmed.replaceFirst(RegExp(r'^[\*\-\+]\s+'), '');
      trimmed = trimmed.replaceFirst(RegExp(r'^\d+[\.\)]\s+'), '');

      // Strip markdown bold/italics/code markers
      trimmed = trimmed
          .replaceAll('**', '')
          .replaceAll('__', '')
          .replaceAll('`', '');

      // Strip PR / commit / author suffixes
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s+in\s+https?://\S+', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s+by\s+@\S+', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s*\(\#\d+\)', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'https?://github\.com/\S+', caseSensitive: false), '');

      trimmed = trimmed.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();
      String? matchedCategory;
      String content = trimmed;

      if (lower.startsWith('feat:') ||
          lower.startsWith('feat!:') ||
          lower.startsWith('feature:')) {
        matchedCategory = 'feature:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('fix:') ||
          lower.startsWith('fix!:') ||
          lower.startsWith('bugfix:')) {
        matchedCategory = 'fix:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('refactor:') ||
          lower.startsWith('refactor!:') ||
          lower.startsWith('perf:') ||
          lower.startsWith('perf!:')) {
        matchedCategory = 'refactor:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('chore:') ||
          lower.startsWith('chore!:') ||
          lower.startsWith('docs:') ||
          lower.startsWith('style:') ||
          lower.startsWith('test:') ||
          lower.startsWith('ci:') ||
          lower.startsWith('build:') ||
          lower.startsWith('revert:')) {
        matchedCategory = 'chore:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      }

      if (matchedCategory != null) {
        currentCategory = matchedCategory;
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          if (!groups[currentCategory]!.contains(content)) {
            groups[currentCategory]!.add(content);
          }
        }
      } else if ((isIndented || !hasCommitMeta) &&
          currentCategory != null &&
          groups[currentCategory]!.isNotEmpty) {
        // Description sub-bullet belonging to the previous entry
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          final parentIdx = groups[currentCategory]!.length - 1;
          groups[currentCategory]![parentIdx] += '\n   • $content';
        }
      } else {
        currentCategory = 'other:';
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          if (!groups['other:']!.contains(content)) {
            groups['other:']!.add(content);
          }
        }
      }
    }

    // Keep only populated categories in order
    final result = <String, List<String>>{};
    for (final key in ['refactor:', 'feature:', 'fix:', 'chore:', 'other:']) {
      if (groups[key]!.isNotEmpty) {
        result[key] = groups[key]!;
      }
    }

    return CategorizedChangelog(result);
  }
}
