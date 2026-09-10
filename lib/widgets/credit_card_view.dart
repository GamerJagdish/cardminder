import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/credit_card.dart';
import '../theme/app_theme.dart';

class CreditCardView extends StatefulWidget {
  final CreditCard card;
  final VoidCallback? onTap;
  final VoidCallback? onCardTypeTap;
  final VoidCallback? onDigitsTap;
  final ValueChanged<String>? onNetworkSelected;
  final bool isInteractive;
  final String? heroTag;
  final bool enableTilt;

  const CreditCardView({
    super.key,
    required this.card,
    this.onTap,
    this.onCardTypeTap,
    this.onDigitsTap,
    this.onNetworkSelected,
    this.isInteractive = true,
    this.heroTag,
    this.enableTilt = true,
  });

  @override
  State<CreditCardView> createState() => _CreditCardViewState();
}

class _CreditCardViewState extends State<CreditCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;
  Offset _currentOffset = Offset.zero;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _springAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    ))..addListener(() {
      setState(() {
        _currentOffset = _springAnimation.value;
      });
    });
  }

  @override
  void deactivate() {
    _resetTiltImmediately();
    super.deactivate();
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _resetTiltImmediately() {
    if (_currentOffset != Offset.zero || _isInteracting) {
      _springController.stop();
      _currentOffset = Offset.zero;
      _isInteracting = false;
    }
  }

  void _updateTilt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final local = box.globalToLocal(globalPosition);
      final normX =
          ((local.dx - box.size.width / 2) / (box.size.width / 2)).clamp(-1.0, 1.0);
      final normY = ((local.dy - box.size.height / 2) / (box.size.height / 2))
          .clamp(-1.0, 1.0);
      setState(() {
        _currentOffset = Offset(normX, normY);
        _isInteracting = true;
      });
    }
  }

  void _releaseTilt() {
    if (!widget.enableTilt) return;
    if (_currentOffset == Offset.zero && !_isInteracting) return;
    _isInteracting = false;
    _springAnimation = Tween<Offset>(
      begin: _currentOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final onTap = widget.onTap;
    final onCardTypeTap = widget.onCardTypeTap;
    final onDigitsTap = widget.onDigitsTap;
    final onNetworkSelected = widget.onNetworkSelected;
    final isInteractive = widget.isInteractive;
    final heroTag = widget.heroTag;
    final colors = AppTheme.getCardColors(card.colorIndex);
    final displayName = card.cardName.isEmpty ? 'Card Nickname' : card.cardName;
    final digits = (card.lastFourDigits == null || card.lastFourDigits!.isEmpty)
        ? '0001'
        : card.lastFourDigits!;

    // Dynamic contrast coloring based on background luminance
    final isLightBg = colors.first.computeLuminance() > 0.45;
    final textColor = isLightBg ? const Color(0xFF0F172A) : Colors.white;
    final textMuted = isLightBg ? const Color(0xFF334155) : Colors.white70;
    final textSubtle = isLightBg ? const Color(0xFF475569) : Colors.white60;
    final iconColor = isLightBg ? const Color(0xFF0F172A) : Colors.white;
    final badgeBg = isLightBg
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.18);
    final badgeBorder = isLightBg ? Colors.black26 : Colors.white38;
    final ambientCircleColor = isLightBg
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.08);

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardShadows = [
      // Primary rich colored glow matching card's unique theme hue (projecting downwards)
      BoxShadow(
        color: colors.first.withValues(alpha: isDarkTheme ? 0.38 : 0.28),
        blurRadius: 22,
        offset: const Offset(0, 9),
      ),
      // Ambient atmospheric colored aura surrounding the card (gentle upward falloff)
      BoxShadow(
        color: colors.first.withValues(alpha: isDarkTheme ? 0.20 : 0.12),
        blurRadius: 14,
        spreadRadius: -2,
        offset: const Offset(0, 3),
      ),
    ];

    final cardWidget = GestureDetector(
      onTap: isInteractive && onTap != null
          ? () {
              _resetTiltImmediately();
              onTap();
            }
          : null,
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
          boxShadow: cardShadows,
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
                    color: ambientCircleColor,
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
                    color: ambientCircleColor,
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayName,
                                key: ValueKey('name-$displayName'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
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
                            color: Theme.of(context).cardTheme.color,
                            surfaceTintColor: Colors.transparent,
                            tooltip: 'Select Network',
                            itemBuilder: (context) {
                              final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
                              final selectedColor = isDarkTheme ? AppTheme.primaryAccentDark : AppTheme.primaryNavy;
                              final itemTextColor = Theme.of(context).colorScheme.onSurface;

                              return [
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
                                              ? selectedColor
                                              : itemTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const Spacer(),
                                        Icon(Icons.check_rounded,
                                            size: 18, color: selectedColor),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: badgeBorder, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutBack,
                                        ),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey('net-${card.network}'),
                                      child: _buildNetworkLogo(card.network),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down_rounded,
                                      color: iconColor, size: 18),
                                ],
                              ),
                            ),
                          )
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey('net-${card.network}'),
                              child: _buildNetworkLogo(card.network),
                            ),
                          ),
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
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: badgeBorder, width: 0.8),
                              )
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '• • • •  • • • •  • • • •  ',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.4),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  digits,
                                  key: ValueKey('digits-$digits'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              if (onDigitsTap != null) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined,
                                    color: textMuted, size: 13),
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
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: textSubtle,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                card.expiryDateString,
                                key: ValueKey('exp-${card.expiryDateString}'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: badgeBorder, width: 0.8),
                                  )
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    card.cardType.toUpperCase(),
                                    key: ValueKey('type-${card.cardType}'),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (onCardTypeTap != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.sync_alt_rounded,
                                      color: textMuted, size: 12),
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
              // Dynamic Holographic Light Sheen Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment(-_currentOffset.dx * 2.5 - 0.4,
                            -_currentOffset.dy * 2.5 - 0.4),
                        end: Alignment(-_currentOffset.dx * 2.5 + 0.4,
                            -_currentOffset.dy * 2.5 + 0.4),
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(
                              alpha: _isInteracting ? 0.24 : 0.07),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.25, 0.5, 0.75],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final tiltAngleX = -_currentOffset.dy * 0.16;
    final tiltAngleY = _currentOffset.dx * 0.16;
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(tiltAngleX)
      ..rotateY(tiltAngleY);

    final interactiveCard = Listener(
      onPointerDown: (event) {
        if (!widget.enableTilt) return;
        _springController.stop();
        _updateTilt(event.position);
      },
      onPointerMove: (event) {
        if (!widget.enableTilt) return;
        _updateTilt(event.position);
      },
      onPointerUp: (_) => _releaseTilt(),
      onPointerCancel: (_) => _releaseTilt(),
      child: Transform(
        transform: tiltMatrix,
        alignment: Alignment.center,
        child: cardWidget,
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        flightShuttleBuilder: (flightContext, animation, flightDirection,
            fromHeroContext, toHeroContext) {
          return Material(
            type: MaterialType.transparency,
            child: toHeroContext.widget,
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: interactiveCard,
        ),
      );
    }

    return interactiveCard;
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
