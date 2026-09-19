import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class CardNetworkLogo extends StatelessWidget {
  final String network;
  final double? height;
  final double? width;
  final Color? color;
  final Color? backgroundColor;

  const CardNetworkLogo({
    super.key,
    required this.network,
    this.height,
    this.width,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final netLower = network.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLightBg = backgroundColor != null
        ? backgroundColor!.computeLuminance() > 0.45
        : (color != null
            ? color!.computeLuminance() < 0.5
            : !isDark);

    final effectiveColor = color ??
        (isLightBg ? AppTheme.primaryNavy : AppTheme.surfaceWhite);

    switch (netLower) {
      case 'mastercard':
        final mcHeight = height ?? 34.0;
        return SvgPicture.asset(
          'assets/logos/mastercard.svg',
          height: mcHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'rupay':
        final assetPath = isLightBg
            ? 'assets/logos/Rupay-Blue.png'
            : 'assets/logos/RuPay-White.png';
        final rupayHeight = height ?? 24.0;
        return Image.asset(
          assetPath,
          height: rupayHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'amex':
      case 'american express':
        final amexHeight = height ?? 40.0;
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: amexHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'discover':
        final discoverHeight = height ?? 36.0;
        return Image.asset(
          'assets/logos/discover.png',
          height: discoverHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'visa':
      default:
        final visaHeight = height ?? 28.0;
        return SvgPicture.asset(
          'assets/logos/visa.svg',
          height: visaHeight,
          width: width,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            effectiveColor,
            BlendMode.srcIn,
          ),
        );
    }
  }
}

/// Animated 3D coin-flip transition for card network logos.
///
/// Rotates 90 degrees edge-on around the Y-axis to 0px width, swaps the logo
/// at the midpoint, and rotates out to 0 degrees flat, seamlessly masking
/// aspect ratio differences without visual jumping.
class FlipCardNetworkLogo extends StatefulWidget {
  final String network;
  final double? height;
  final double? width;
  final Color? color;
  final Color? backgroundColor;

  const FlipCardNetworkLogo({
    super.key,
    required this.network,
    this.height,
    this.width,
    this.color,
    this.backgroundColor,
  });

  @override
  State<FlipCardNetworkLogo> createState() => _FlipCardNetworkLogoState();
}

class _FlipCardNetworkLogoState extends State<FlipCardNetworkLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _currentNetwork;
  late String _targetNetwork;

  @override
  void initState() {
    super.initState();
    _currentNetwork = widget.network;
    _targetNetwork = widget.network;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _currentNetwork = _targetNetwork;
              _controller.reset();
            });
          }
        }
      });
  }

  @override
  void didUpdateWidget(FlipCardNetworkLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.network.toLowerCase() != _currentNetwork.toLowerCase()) {
      _targetNetwork = widget.network;
      _controller.forward(from: 0.0);
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
        final activeNetwork = isFirstHalf ? _currentNetwork : _targetNetwork;

        final double angle;
        if (!_controller.isAnimating && _currentNetwork == _targetNetwork) {
          angle = 0.0;
        } else if (isFirstHalf) {
          final progress = Curves.easeInQuad.transform(val * 2.0);
          angle = progress * (math.pi / 2);
        } else {
          final progress = Curves.easeOutQuad.transform((val - 0.5) * 2.0);
          angle = -(math.pi / 2) * (1.0 - progress);
        }

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: CardNetworkLogo(
            key: ValueKey('flip-logo-$activeNetwork'),
            network: activeNetwork,
            height: widget.height,
            width: widget.width,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
          ),
        );
      },
    );
  }
}

