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
        (isLightBg ? AppTheme.textDark : AppTheme.surfaceWhite);

    final defaultHeight = height ?? 34.0;

    switch (netLower) {
      case 'mastercard':
        final mcHeight = height ?? 38.0;
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
        return Image.asset(
          assetPath,
          height: defaultHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'amex':
      case 'american express':
        final amexHeight = height ?? 38.0;
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: amexHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'discover':
        final discoverHeight = height ?? 38.0;
        return Image.asset(
          'assets/logos/discover.png',
          height: discoverHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'visa':
      default:
        return SvgPicture.asset(
          'assets/logos/visa.svg',
          height: defaultHeight,
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
