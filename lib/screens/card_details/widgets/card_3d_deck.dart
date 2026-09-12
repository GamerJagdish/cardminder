import 'package:flutter/material.dart';
import '../../../models/credit_card.dart';
import '../../../widgets/credit_card_view.dart';

class Card3DDeck extends StatelessWidget {
  final CreditCard currentCard;
  final CreditCard? prevCard;
  final CreditCard? nextCard;
  final bool hasPrev;
  final bool hasNext;
  final double dragOffset;
  final double pullDownOffset;

  const Card3DDeck({
    super.key,
    required this.currentCard,
    required this.prevCard,
    required this.nextCard,
    required this.hasPrev,
    required this.hasNext,
    required this.dragOffset,
    required this.pullDownOffset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dragFraction = (dragOffset / screenWidth).clamp(-1.0, 1.0);
    final absOffset = dragOffset.abs();
    final switchProgress = (absOffset / 200.0).clamp(0.0, 1.0);

    // Determine which background card to display in the 3D depth stack
    final CreditCard? backgroundCard = dragOffset < 0
        ? nextCard
        : (dragOffset > 0 ? prevCard : (hasNext ? nextCard : null));

    // Background card transforms (emerging from 3D depth)
    final bgScale = 0.92 + (0.08 * switchProgress);
    final bgOpacity = dragOffset == 0.0
        ? (hasNext ? (isDark ? 0.20 : 0.28) : 0.0)
        : (0.35 + 0.65 * switchProgress).clamp(0.0, 1.0);
    final bgTranslateY = (1.0 - switchProgress) * 10.0;
    final bgAngleY = dragOffset < 0
        ? (1.0 - switchProgress) * 0.12
        : (dragOffset > 0 ? -(1.0 - switchProgress) * 0.12 : 0.0);

    final bgMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(
          0.0, bgTranslateY, -35.0 * (1.0 - switchProgress), 1.0)
      ..rotateY(bgAngleY);

    // Front card transforms (interactive 3D perspective rotation, wrist tilt, tension scale)
    final frontAngleY = -dragFraction * 0.70;
    final frontAngleZ = dragFraction * 0.12;
    final frontScale =
        (1.0 - (absOffset / screenWidth) * 0.08).clamp(0.92, 1.0);
    final frontOpacity = absOffset > 70
        ? (1.0 - (absOffset - 70) / (screenWidth * 0.7)).clamp(0.0, 1.0)
        : 1.0;

    final frontMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(dragOffset, 0.0, 0.0, 1.0)
      ..rotateY(frontAngleY)
      ..rotateZ(frontAngleZ);

    return SizedBox(
      height: 195,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Background Card Layer (Physical 3D Depth Layer)
          if (backgroundCard != null && bgOpacity > 0.01)
            Transform(
              transform: bgMatrix,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: bgScale,
                child: Opacity(
                  opacity: bgOpacity,
                  child: IgnorePointer(
                    child: CreditCardView(
                      key: ValueKey('bg-card-${backgroundCard.id}'),
                      card: backgroundCard,
                      heroTag: null,
                      isInteractive: false,
                      enableTilt: false,
                    ),
                  ),
                ),
              ),
            ),

          // 2. Foreground Active Card Layer (3D perspective tilt & interactive motion)
          Transform(
            transform: frontMatrix,
            alignment: Alignment.center,
            child: Transform.scale(
              scale: frontScale,
              child: Opacity(
                opacity: frontOpacity,
                child: CreditCardView(
                  key: ValueKey('front-card-${currentCard.id}'),
                  card: currentCard,
                  heroTag: 'card-hero-${currentCard.id}',
                  isInteractive: true,
                  enableTilt: dragOffset == 0.0 && pullDownOffset == 0.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
