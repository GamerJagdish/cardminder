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

