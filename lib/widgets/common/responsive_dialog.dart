import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable responsive dialog container that automatically handles
/// landscape/portrait constraints, screen margins, and CardMinder styling.
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double maxWidth;
  final double borderRadius;
  final EdgeInsets? padding;
  final bool clipContent;
  final Color? backgroundColor;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.minWidth = 320.0,
    this.maxWidth = 440.0,
    this.borderRadius = 24.0,
    this.padding,
    this.clipContent = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final horizontalInset = screenWidth < 500 ? 16.0 : 24.0;
    final verticalInset =
        isLandscape || screenHeight < 500 ? 12.0 : 24.0;
    final availableWidth = screenWidth - (horizontalInset * 2);
    final dialogWidth = availableWidth.clamp(minWidth, maxWidth);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final effectivePadding = padding != null
        ? (isLandscape || screenHeight < 500
            ? EdgeInsets.only(
                left: padding!.left,
                right: padding!.right,
                top: padding!.top.clamp(0.0, 16.0),
                bottom: padding!.bottom.clamp(0.0, 16.0),
              )
            : padding!)
        : null;

    final Widget dialogBody;
    if (child is SingleChildScrollView) {
      dialogBody = effectivePadding != null
          ? Padding(padding: effectivePadding, child: child)
          : child;
    } else {
      dialogBody = SingleChildScrollView(
        padding: effectivePadding,
        child: child,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
      backgroundColor: backgroundColor ?? context.colors.surfaceCard,
      elevation: isDark ? 12 : 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          minWidth: dialogWidth,
        ),
        child: dialogBody,
      ),
    );
  }
}
