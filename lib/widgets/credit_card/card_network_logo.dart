import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final effectiveColor = color ??
        (backgroundColor != null
            ? (backgroundColor!.computeLuminance() > 0.45
                ? const Color(0xFF0F172A)
                : Colors.white)
            : (isDark ? Colors.white : const Color(0xFF0F172A)));

    final defaultHeight = height ?? 36;

    switch (netLower) {
      case 'mastercard':
        return SvgPicture.asset(
          'assets/logos/mastercard.svg',
          height: defaultHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'rupay':
        final imgHeight = defaultHeight > 8 ? defaultHeight - 8 : defaultHeight;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/rupay.png',
            height: imgHeight,
            width: width,
            fit: BoxFit.contain,
          ),
        );
      case 'amex':
      case 'american express':
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: defaultHeight,
          width: width,
          fit: BoxFit.contain,
        );
      case 'discover':
        final imgHeight = defaultHeight > 8 ? defaultHeight - 8 : defaultHeight;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/discover.png',
            height: imgHeight,
            width: width,
            fit: BoxFit.contain,
          ),
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
