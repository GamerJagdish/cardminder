import 'package:flutter/material.dart';
import '../../screens/add_edit_card_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';

class HomeBottomNavBar extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onHomeReselected;
  final ValueChanged<String>? onCardAdded;

  const HomeBottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onHomeReselected,
    this.onCardAdded,
  });

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar> {
  final GlobalKey _addCardPillKey = GlobalKey();
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy;
    final inactiveColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Left Tab: Home
            Expanded(
              child: InkWell(
                onTap: () {
                  if (widget.selectedTab == 0) {
                    widget.onHomeReselected();
                  } else {
                    widget.onTabSelected(0);
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selectedTab == 0
                            ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.selectedTab == 0
                            ? Icons.home_rounded
                            : Icons.home_outlined,
                        color: widget.selectedTab == 0
                            ? activeColor
                            : inactiveColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: widget.selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: widget.selectedTab == 0
                            ? activeColor
                            : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Tab: Add Card Button
            Expanded(
              child: InkWell(
                onTapDown: (details) {
                  _tapPosition = details.globalPosition;
                },
                onTap: () async {
                  final pillBox = _addCardPillKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  final originRect = pillBox != null && pillBox.hasSize
                      ? pillBox.localToGlobal(Offset.zero) & pillBox.size
                      : null;
                  final center = originRect?.center ?? _tapPosition;
                  _tapPosition = null;

                  final addedCardId = await Navigator.push<String?>(
                    context,
                    pillRevealRoute(
                      const AddEditCardScreen(),
                      originRect: originRect,
                      center: center,
                    ),
                  );
                  if (addedCardId != null && mounted) {
                    widget.onCardAdded?.call(addedCardId);
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      key: _addCardPillKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_card_rounded,
                        color: isDark ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add Card',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Tab: Settings
            Expanded(
              child: InkWell(
                onTap: () => widget.onTabSelected(1),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selectedTab == 1
                            ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.selectedTab == 1
                            ? Icons.settings_rounded
                            : Icons.settings_outlined,
                        color: widget.selectedTab == 1
                            ? activeColor
                            : inactiveColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: widget.selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: widget.selectedTab == 1
                            ? activeColor
                            : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
