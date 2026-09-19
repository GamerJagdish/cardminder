import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'card_network_logo.dart';

enum FlipAxis { horizontal, vertical }

/// A generic widget that performs a smooth 3D flip transition when its [value] changes.
///
/// At the 90-degree midpoint (100ms for a 200ms duration), projected width (horizontal)
/// or height (vertical) is exactly 0px, where the child swaps seamlessly with zero visual jumping.
class Flip3D<T> extends StatefulWidget {
  final T value;
  final Widget Function(BuildContext context, T value) builder;
  final FlipAxis axis;
  final Duration duration;
  final Alignment alignment;
  final bool randomizeDirection;

  const Flip3D({
    super.key,
    required this.value,
    required this.builder,
    this.axis = FlipAxis.horizontal,
    this.duration = const Duration(milliseconds: 200),
    this.alignment = Alignment.center,
    this.randomizeDirection = true,
  });

  @override
  State<Flip3D<T>> createState() => _Flip3DState<T>();
}

class _Flip3DState<T> extends State<Flip3D<T>>
    with SingleTickerProviderStateMixin {
  static final math.Random _random = math.Random();
  late AnimationController _controller;
  late T _currentValue;
  late T _targetValue;
  double _direction = 1.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _targetValue = widget.value;
    if (widget.randomizeDirection) {
      _direction = _random.nextBool() ? 1.0 : -1.0;
    }
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _currentValue = _targetValue;
              _controller.reset();
            });
          }
        }
      });
  }

  @override
  void didUpdateWidget(Flip3D<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _targetValue) {
      if (_controller.isAnimating && _controller.value >= 0.5) {
        _currentValue = _targetValue;
      }
      _targetValue = widget.value;
      if (_currentValue == _targetValue) {
        _controller.reset();
      } else {
        if (widget.randomizeDirection) {
          _direction = _random.nextBool() ? 1.0 : -1.0;
        }
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final isFirstHalf = val < 0.5;
        final activeValue = isFirstHalf ? _currentValue : _targetValue;

        final double angle;
        if (!_controller.isAnimating && _currentValue == _targetValue) {
          angle = 0.0;
        } else if (isFirstHalf) {
          final progress = Curves.easeInQuad.transform(val * 2.0);
          angle = progress * (math.pi / 2);
        } else {
          final progress = Curves.easeOutQuad.transform((val - 0.5) * 2.0);
          angle = -(math.pi / 2) * (1.0 - progress);
        }

        final Matrix4 transform;
        if (widget.axis == FlipAxis.horizontal) {
          transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle * _direction);
        } else {
          transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX(-angle * _direction);
        }

        return Transform(
          transform: transform,
          alignment: widget.alignment,
          child: widget.builder(context, activeValue),
        );
      },
    );
  }
}

/// Convenient 3D flip widget specialized for text.
class Flip3DText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final FlipAxis axis;
  final Duration duration;
  final Alignment alignment;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;
  final bool randomizeDirection;

  const Flip3DText({
    super.key,
    required this.text,
    this.style,
    this.axis = FlipAxis.horizontal,
    this.duration = const Duration(milliseconds: 200),
    this.alignment = Alignment.center,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textAlign,
    this.randomizeDirection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Flip3D<String>(
      value: text,
      axis: axis,
      duration: duration,
      alignment: alignment,
      randomizeDirection: randomizeDirection,
      builder: (context, activeText) => Text(
        activeText,
        key: ValueKey('flip-text-$activeText'),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        textAlign: textAlign,
      ),
    );
  }
}

/// Animated 3D coin-flip transition for card network logos.
class FlipCardNetworkLogo extends StatelessWidget {
  final String network;
  final double? height;
  final double? width;
  final Color? color;
  final Color? backgroundColor;
  final Duration duration;
  final bool randomizeDirection;

  const FlipCardNetworkLogo({
    super.key,
    required this.network,
    this.height,
    this.width,
    this.color,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 200),
    this.randomizeDirection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Flip3D<String>(
      value: network,
      axis: FlipAxis.horizontal,
      duration: duration,
      alignment: Alignment.center,
      randomizeDirection: randomizeDirection,
      builder: (context, activeNetwork) => CardNetworkLogo(
        key: ValueKey('flip-logo-$activeNetwork'),
        network: activeNetwork,
        height: height,
        width: width,
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
