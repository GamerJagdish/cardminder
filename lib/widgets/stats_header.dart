import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';

class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Total Cards Stat Card
          Expanded(
            child: _StatCard(
              title: 'Total Cards',
              value: '${state.totalCards}',
              icon: Icons.credit_card_rounded,
              color: AppTheme.primaryViolet,
              isSelected: state.filter == FilterType.all,
              onTap: () => ref
                  .read(cardNotifierProvider.notifier)
                  .setFilter(FilterType.all),
            ),
          ),
          const SizedBox(width: 10),

          // Action Required Stat Card (<30 days)
          Expanded(
            child: _StatCard(
              title: 'Action Needed',
              value: '${state.actionRequiredCount}',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.accentRose,
              isSelected: state.filter == FilterType.actionRequired,
              onTap: () => ref
                  .read(cardNotifierProvider.notifier)
                  .setFilter(FilterType.actionRequired),
            ),
          ),
          const SizedBox(width: 10),

          // Safe Stat Card (>30 days)
          Expanded(
            child: _StatCard(
              title: 'Safe',
              value: '${state.safeCount}',
              icon: Icons.shield_rounded,
              color: AppTheme.accentEmerald,
              isSelected: state.filter == FilterType.safe,
              onTap: () => ref
                  .read(cardNotifierProvider.notifier)
                  .setFilter(FilterType.safe),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
