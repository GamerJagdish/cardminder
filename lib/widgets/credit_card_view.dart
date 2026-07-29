import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/credit_card.dart';
import '../theme/app_theme.dart';

class CreditCardView extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onTap;
  final VoidCallback? onCardTypeTap;
  final VoidCallback? onDigitsTap;
  final ValueChanged<String>? onNetworkSelected;
  final bool isInteractive;

  const CreditCardView({
    super.key,
    required this.card,
    this.onTap,
    this.onCardTypeTap,
    this.onDigitsTap,
    this.onNetworkSelected,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getCardColors(card.colorIndex);
    final displayName = card.cardName.isEmpty ? 'Card Nickname' : card.cardName;
    final digits = (card.lastFourDigits == null || card.lastFourDigits!.isEmpty)
        ? '0001'
        : card.lastFourDigits!;

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
                    // Top Row: Card Nickname & Network Logo
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
                        if (onNetworkSelected != null)
                          PopupMenuButton<String>(
                            onSelected: onNetworkSelected,
                            offset: const Offset(0, 36),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            tooltip: 'Select Network',
                            itemBuilder: (context) => [
                              'Visa',
                              'Mastercard',
                              'RuPay',
                              'Amex',
                              'Discover',
                            ].map((net) {
                              final isSelected = card.network.toLowerCase() ==
                                  net.toLowerCase();
                              return PopupMenuItem<String>(
                                value: net,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      height: 26,
                                      child: Center(child: _buildNetworkLogo(net)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      net,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryNavy
                                            : AppTheme.textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const Spacer(),
                                      const Icon(Icons.check_rounded,
                                          size: 18, color: AppTheme.primaryNavy),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white38, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNetworkLogo(card.network),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down_rounded,
                                      color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          )
                        else
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
                    GestureDetector(
                      onTap: onDigitsTap,
                      child: Container(
                        padding: onDigitsTap != null
                            ? const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2)
                            : EdgeInsets.zero,
                        decoration: onDigitsTap != null
                            ? BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white38, width: 0.8),
                              )
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '• • • •  • • • •  • • • •  ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                digits,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (onDigitsTap != null) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined,
                                    color: Colors.white70, size: 13),
                              ],
                            ],
                          ),
                        ),
                      ),
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

                        GestureDetector(
                          onTap: onCardTypeTap,
                          child: Container(
                            padding: onCardTypeTap != null
                                ? const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4)
                                : EdgeInsets.zero,
                            decoration: onCardTypeTap != null
                                ? BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white38, width: 0.8),
                                  )
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  card.cardType.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (onCardTypeTap != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.sync_alt_rounded,
                                      color: Colors.white70, size: 12),
                                ],
                              ],
                            ),
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
          height: 32,
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
            height: 22,
            fit: BoxFit.contain,
          ),
        );
      case 'amex':
      case 'american express':
        return SvgPicture.asset(
          'assets/logos/amex.svg',
          height: 32,
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
            height: 22,
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
            height: 22,
            fit: BoxFit.contain,
          ),
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
