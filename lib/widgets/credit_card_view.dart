import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/credit_card.dart';
import '../theme/app_theme.dart';

class CreditCardView extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onTap;
  final bool isInteractive;

  const CreditCardView({
    super.key,
    required this.card,
    this.onTap,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.cardThemes[card.colorIndex % AppTheme.cardThemes.length];
    final displayName = card.cardName.isEmpty ? 'Card Nickname' : card.cardName;
    final digits = card.lastFourDigits ?? '0000';

    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: Container(
        height: 195,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Top Right ambient circle overlay
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Bottom Left ambient circle overlay
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Card Content Padding
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Card Nickname & Network Logo (Fixed Overflow using Expanded)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildNetworkLogo(card.network),
                      ],
                    ),

                    // EMV Chip
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE066), Color(0xFFD4AF37)],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _ChipGridPainter(),
                      ),
                    ),

                    // Masked Digits + Last 4 Digits
                    Row(
                      children: [
                        const Text(
                          '• • • •   • • • •   • • • •   ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          digits,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: EXPIRES & Card Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.expiryDateString,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          card.cardType,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkLogo(String network) {
    final netLower = network.toLowerCase();
    switch (netLower) {
      case 'mastercard':
        return Image.asset(
          'assets/logos/mastercard.png',
          height: 26,
          fit: BoxFit.contain,
        );
      case 'rupay':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/rupay.png',
            height: 18,
            fit: BoxFit.contain,
          ),
        );
      case 'amex':
      case 'american express':
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: 26,
          fit: BoxFit.contain,
        );
      case 'discover':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/logos/discover.png',
            height: 18,
            fit: BoxFit.contain,
          ),
        );
      case 'visa':
      default:
        return Image.asset(
          'assets/logos/visa.png',
          height: 22,
          fit: BoxFit.contain,
        );
    }
  }
}

class _ChipGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.4);

    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width, size.height * 0.7);

    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.4, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
