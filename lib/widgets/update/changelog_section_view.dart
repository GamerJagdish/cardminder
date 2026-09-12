import 'package:flutter/material.dart';
import '../../models/categorized_changelog.dart';
import '../../theme/app_theme.dart';

/// Helper widget methods for rendering categorized release notes and changelog tags.
class ChangelogSectionHelper {
  static String categoryTitle(String key) {
    switch (key) {
      case 'feature:':
        return 'Features';
      case 'fix:':
        return 'Bug Fixes';
      case 'refactor:':
        return 'Improvements';
      case 'chore:':
        return 'Maintenance';
      case 'other:':
      default:
        return 'Other Changes';
    }
  }

  static Color categoryColor(String key) {
    switch (key) {
      case 'feature:':
        return AppTheme.accentEmerald;
      case 'fix:':
        return const Color(0xFFF43F5E); // Rose 500
      case 'refactor:':
        return const Color(0xFF38BDF8); // Sky 400
      case 'chore:':
        return const Color(0xFFA78BFA); // Violet 400
      case 'other:':
      default:
        return const Color(0xFF94A3B8); // Slate 400
    }
  }

  static Widget buildCategorizedNotes({
    required BuildContext context,
    required CategorizedChangelog changelog,
    required String rawNotes,
    required bool isDark,
  }) {
    if (changelog.isEmpty) {
      final fallback = rawNotes.trim().isNotEmpty
          ? rawNotes.trim()
          : 'Performance enhancements and bug fixes.';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          fallback,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            letterSpacing: 0.15,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in changelog.categories.entries) ...[
          // Category Pill Badge
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: categoryColor(entry.key)
                  .withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: categoryColor(entry.key)
                    .withValues(alpha: isDark ? 0.28 : 0.20),
                width: 0.8,
              ),
            ),
            child: Text(
              categoryTitle(entry.key),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: categoryColor(entry.key),
                letterSpacing: 0.3,
              ),
            ),
          ),
          // List of items in this category
          for (int i = 0; i < entry.value.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12, right: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8.5, right: 10, left: 2),
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Expanded(
                    child: _buildItemContent(entry.value[i], isDark),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  static Widget _buildItemContent(String rawItem, bool isDark) {
    if (rawItem.contains('\n')) {
      final parts = rawItem.split('\n');
      final title = parts.first;
      final subLines = parts.sublist(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.50,
              letterSpacing: 0.15,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
          for (final sub in subLines)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                sub.trim(),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.50,
                  letterSpacing: 0.1,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      );
    }

    return Text(
      rawItem,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        letterSpacing: 0.15,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Subtle gradient fade indicator at the bottom of changelog scroll views.
class BottomScrollHintOverlay extends StatelessWidget {
  final bool isDark;

  const BottomScrollHintOverlay({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 24,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surfaceColor.withValues(alpha: 0.0),
                surfaceColor.withValues(alpha: 0.35),
                surfaceColor.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
