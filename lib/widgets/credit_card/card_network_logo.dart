import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardNetworkLogo extends StatelessWidget {
  final String network;
  final double? height;

  const CardNetworkLogo({
    super.key,
    required this.network,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final netLower = network.toLowerCase();
    switch (netLower) {
      case 'mastercard':
        return Image.asset(
          'assets/logos/mastercard.png',
          height: height ?? 32,
          fit: BoxFit.contain,
        );
      case 'rupay':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/rupay.png',
            height: height ?? 22,
            fit: BoxFit.contain,
          ),
        );
      case 'amex':
      case 'american express':
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: height ?? 32,
          fit: BoxFit.contain,
        );
      case 'discover':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/discover.png',
            height: height ?? 22,
            fit: BoxFit.contain,
          ),
        );
      case 'visa':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/visa.png',
            height: height ?? 22,
            fit: BoxFit.contain,
          ),
        );
    }
  }
}
