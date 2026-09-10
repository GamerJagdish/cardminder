import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Page route transition that slides up smoothly from bottom to top with subtle fade.
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final slideTween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final fadeTween =
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

/// Page route transition that zooms/scales out gracefully from the center of the screen.
Route<T> zoomFromCenterRoute<T>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final scaleTween =
          Tween<double>(begin: 0.85, end: 1.0).chain(CurveTween(curve: curve));
      final fadeTween =
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          alignment: Alignment.center,
          scale: animation.drive(scaleTween),
          child: child,
        ),
      );
    },
  );
}

/// Custom clipper that creates an expanding circular reveal mask.
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? center;

  const CircularRevealClipper({
    required this.fraction,
    this.center,
  });

  @override
  Path getClip(Size size) {
    if (fraction <= 0.0) {
      return Path();
    }
    if (fraction >= 1.0) {
      return Path()..addRect(Offset.zero & size);
    }

    final focalPoint = center ?? Offset(size.width / 2, size.height / 2);
    final dx = math.max(focalPoint.dx, size.width - focalPoint.dx);
    final dy = math.max(focalPoint.dy, size.height - focalPoint.dy);
    final maxRadius = math.sqrt(dx * dx + dy * dy);

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: focalPoint,
          radius: maxRadius * fraction,
        ),
      );
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) =>
      fraction != oldClipper.fraction || center != oldClipper.center;
}

/// Custom painter that draws a vibrant, glowing colored border ring around the expanding circular reveal.
class CircularRevealBorderPainter extends CustomPainter {
  final double fraction;
  final Offset? center;
  final Color color;
  final double borderWidth;

  const CircularRevealBorderPainter({
    required this.fraction,
    this.center,
    required this.color,
    this.borderWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0.0 || fraction >= 1.0) return;

    // Gracefully fade in during initial 2% and fade out during final 6% of expansion
    double opacity = 1.0;
    if (fraction > 0.94) {
      opacity = ((1.0 - fraction) / 0.06).clamp(0.0, 1.0);
    } else if (fraction < 0.02) {
      opacity = (fraction / 0.02).clamp(0.0, 1.0);
    }

    if (opacity <= 0.0) return;

    final focalPoint = center ?? Offset(size.width / 2, size.height / 2);
    final dx = math.max(focalPoint.dx, size.width - focalPoint.dx);
    final dy = math.max(focalPoint.dy, size.height - focalPoint.dy);
    final maxRadius = math.sqrt(dx * dx + dy * dy);
    final currentRadius = maxRadius * fraction;

    if (currentRadius <= 1.0) return;

    final isLightColor = color.computeLuminance() > 0.5;

    // Outer subtle ambient glow / shadow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + (isLightColor ? 3.0 : 1.5)
      ..color = color.withValues(alpha: (isLightColor ? 0.35 : 0.15) * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(focalPoint, currentRadius, glowPaint);

    // Inner sharp, high-contrast solid stroke
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = color.withValues(alpha: 0.95 * opacity);
    canvas.drawCircle(focalPoint, currentRadius, borderPaint);
  }

  @override
  bool shouldRepaint(CircularRevealBorderPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        center != oldDelegate.center ||
        color != oldDelegate.color ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// Page route transition that expands outward in a circle from a focal point (e.g., where a button was clicked),
/// accented with a crisp border ring matching the app's native light and dark theme colors.
Route<T> circularRevealRoute<T>(
  Widget page, {
  Offset? center,
  Color? borderColor,
  double borderWidth = 2.5,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Duration reverseTransitionDuration = const Duration(milliseconds: 350),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, animChild) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final effectiveColor = borderColor ??
              (isDark ? Colors.white : AppTheme.primaryNavy);

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: CircularRevealClipper(
                  fraction: curvedAnimation.value,
                  center: center,
                ),
                child: animChild,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: CircularRevealBorderPainter(
                    fraction: curvedAnimation.value,
                    center: center,
                    color: effectiveColor,
                    borderWidth: borderWidth,
                  ),
                ),
              ),
            ],
          );
        },
        child: child,
      );
    },
  );
}

/// Custom clipper that creates an expanding rounded rectangle (pill/squircle) reveal mask.
class PillRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Rect? originRect;
  final Offset? center;

  const PillRevealClipper({
    required this.fraction,
    this.originRect,
    this.center,
  });

  @override
  Path getClip(Size size) {
    if (fraction <= 0.0) {
      return Path();
    }
    if (fraction >= 1.0) {
      return Path()..addRect(Offset.zero & size);
    }

    final screenRect = Offset.zero & size;
    final focalPoint = center ?? Offset(size.width / 2, size.height - 40);
    final startRect = originRect ??
        Rect.fromCenter(center: focalPoint, width: 48, height: 28);

    final currentRect = Rect.lerp(startRect, screenRect, fraction)!;

    // Maintain rounded squarish/pill corners during expansion, then smoothly uncurl as it docks
    double cornerRadius;
    if (fraction < 0.75) {
      cornerRadius = 12.0 + 8.0 * fraction;
    } else {
      cornerRadius = (12.0 + 8.0 * 0.75) * (1.0 - fraction) / 0.25;
    }

    final rrect = RRect.fromRectAndRadius(
      currentRect,
      Radius.circular(cornerRadius),
    );

    return Path()..addRRect(rrect);
  }

  @override
  bool shouldReclip(PillRevealClipper oldClipper) =>
      fraction != oldClipper.fraction ||
      originRect != oldClipper.originRect ||
      center != oldClipper.center;
}

/// Custom painter that draws a vibrant, glowing colored border around the expanding rounded pill.
class PillRevealBorderPainter extends CustomPainter {
  final double fraction;
  final Rect? originRect;
  final Offset? center;
  final Color color;
  final double borderWidth;

  const PillRevealBorderPainter({
    required this.fraction,
    this.originRect,
    this.center,
    required this.color,
    this.borderWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0.0 || fraction >= 1.0) return;

    // Gracefully fade in during initial 2% and fade out during final 6% of expansion
    double opacity = 1.0;
    if (fraction > 0.94) {
      opacity = ((1.0 - fraction) / 0.06).clamp(0.0, 1.0);
    } else if (fraction < 0.02) {
      opacity = (fraction / 0.02).clamp(0.0, 1.0);
    }

    if (opacity <= 0.0) return;

    final screenRect = Offset.zero & size;
    final focalPoint = center ?? Offset(size.width / 2, size.height - 40);
    final startRect = originRect ??
        Rect.fromCenter(center: focalPoint, width: 48, height: 28);

    final currentRect = Rect.lerp(startRect, screenRect, fraction)!;

    double cornerRadius;
    if (fraction < 0.85) {
      cornerRadius = 12.0 + 6.0 * fraction;
    } else {
      cornerRadius = (12.0 + 6.0 * 0.85) * (1.0 - fraction) / 0.15;
    }

    final rrect = RRect.fromRectAndRadius(
      currentRect,
      Radius.circular(cornerRadius),
    );

    final isLightColor = color.computeLuminance() > 0.5;

    // Outer subtle ambient glow / shadow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + (isLightColor ? 3.0 : 1.5)
      ..color = color.withValues(alpha: (isLightColor ? 0.35 : 0.15) * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect, glowPaint);

    // Inner sharp solid stroke
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = color.withValues(alpha: 0.95 * opacity);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(PillRevealBorderPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        originRect != oldDelegate.originRect ||
        center != oldDelegate.center ||
        color != oldDelegate.color ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// Page route transition that expands outward from a rounded rectangular pill shape (matching the tapped button),
/// accented with a crisp border ring matching the app's native light and dark theme colors.
Route<T> pillRevealRoute<T>(
  Widget page, {
  Rect? originRect,
  Offset? center,
  Color? borderColor,
  double borderWidth = 2.5,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Duration reverseTransitionDuration = const Duration(milliseconds: 350),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, animChild) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final effectiveColor = borderColor ??
              (isDark ? Colors.white : AppTheme.primaryNavy);

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: PillRevealClipper(
                  fraction: curvedAnimation.value,
                  originRect: originRect,
                  center: center,
                ),
                child: animChild,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: PillRevealBorderPainter(
                    fraction: curvedAnimation.value,
                    originRect: originRect,
                    center: center,
                    color: effectiveColor,
                    borderWidth: borderWidth,
                  ),
                ),
              ),
            ],
          );
        },
        child: child,
      );
    },
  );
}

