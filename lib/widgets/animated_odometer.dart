import 'package:flutter/material.dart';

/// An animated rolling counter that transitions between numeric values
/// with a mechanical odometer roll effect.
class AnimatedOdometerText extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final String? suffix;

  const AnimatedOdometerText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutCubic,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        final int currentInt = animatedValue.round();
        final String digits = currentInt.toString();

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            for (int i = 0; i < digits.length; i++)
              _OdometerDigit(
                digit: digits[i],
                style: style,
                key: ValueKey('odometer-pos-$i-${digits.length}'),
              ),
            if (suffix != null)
              Text(
                suffix!,
                style: style,
              ),
          ],
        );
      },
    );
  }
}

class _OdometerDigit extends StatelessWidget {
  final String digit;
  final TextStyle style;

  const _OdometerDigit({
    super.key,
    required this.digit,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.45),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        digit,
        key: ValueKey('digit-$digit'),
        style: style,
      ),
    );
  }
}
