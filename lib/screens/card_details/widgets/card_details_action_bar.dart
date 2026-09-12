import 'package:flutter/material.dart';
import '../../../models/credit_card.dart';
import '../../../theme/app_theme.dart';

class CardDetailsActionBar extends StatelessWidget {
  final CreditCard card;
  final bool isResetting;
  final VoidCallback? onMarkUsedToday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CardDetailsActionBar({
    super.key,
    required this.card,
    required this.isResetting,
    required this.onMarkUsedToday,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary Action Button: "Mark Transaction Today"
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isResetting ? null : onMarkUsedToday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isResetting
                      ? AppTheme.accentEmerald
                      : (isDark
                          ? AppTheme.primaryAccentDark
                          : AppTheme.primaryNavy),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isResetting
                      ? const Row(
                          key: ValueKey('resetting'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Reset Complete!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Mark Transaction Today',
                          key: const ValueKey('idle'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Secondary Actions Row: Solid Edit & Delete Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRose,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
