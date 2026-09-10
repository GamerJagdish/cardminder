import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_odometer.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'add_edit_card_screen.dart';

class CardDetailsScreen extends ConsumerStatefulWidget {
  final CreditCard card;

  const CardDetailsScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends ConsumerState<CardDetailsScreen>
    with TickerProviderStateMixin {
  late String _currentCardId;
  bool _isResetting = false;
  bool _showCelebration = false;

  // Vertical Pull-Down Dismiss
  double _pullDownOffset = 0.0;
  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  // Horizontal 3D Card Deck Switcher
  double _dragOffset = 0.0;
  Axis? _dragAxis;
  Offset? _panStartPosition;
  late AnimationController _deckController;
  late Animation<double> _deckAnimation;

  @override
  void initState() {
    super.initState();
    _currentCardId = widget.card.id;

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {
          _pullDownOffset = _springBackAnimation.value;
        });
      });
    _springBackAnimation = const AlwaysStoppedAnimation<double>(0.0);

    _deckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        setState(() {
          _dragOffset = _deckAnimation.value;
        });
      });
    _deckAnimation = const AlwaysStoppedAnimation<double>(0.0);
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _deckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(cardNotifierProvider);
    final filteredCards = cardState.filteredCards;
    final activeIndex =
        filteredCards.indexWhere((c) => c.id == _currentCardId);
    final currentIndex = activeIndex != -1
        ? activeIndex
        : (filteredCards.isNotEmpty ? 0 : -1);

    final currentCard = currentIndex != -1
        ? filteredCards[currentIndex]
        : cardState.cards.firstWhere(
            (c) => c.id == _currentCardId,
            orElse: () => widget.card,
          );

    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < filteredCards.length - 1;
    final prevCard = hasPrev ? filteredCards[currentIndex - 1] : null;
    final nextCard = hasNext ? filteredCards[currentIndex + 1] : null;

    final dateFormat = DateFormat('MMM dd, yyyy');
    final urgency = currentCard.status;
    final progress = currentCard.elapsedProgress;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, currentCard.id);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, currentCard.id),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              currentCard.cardName,
              key: ValueKey('title-${currentCard.id}'),
            ),
          ),
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Layer 0 (Underneath): Content with invisible placeholder to reserve card space
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Placeholder space matching pull-down indicator
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                        ),
                      ),

                      // Invisible card placeholder to naturally size layout
                      Opacity(
                        opacity: 0.0,
                        child: IgnorePointer(
                          child: CreditCardView(
                            card: currentCard,
                            heroTag: null,
                            isInteractive: false,
                            enableTilt: false,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                  // Countdown Progress Banner Card with Celebration Ripple
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _showCelebration
                          ? AppTheme.accentEmerald
                              .withValues(alpha: isDark ? 0.20 : 0.10)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showCelebration
                            ? AppTheme.accentEmerald
                                .withValues(alpha: isDark ? 0.5 : 0.35)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _showCelebration
                              ? AppTheme.accentEmerald
                                  .withValues(alpha: isDark ? 0.25 : 0.15)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: _showCelebration ? 18 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Circular Progress Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                    begin: 0.0,
                                    end: (1.0 - progress).clamp(0.0, 1.0)),
                                duration: const Duration(milliseconds: 750),
                                curve: Curves.easeOutCubic,
                                builder: (context, animatedValue, _) {
                                  return CircularProgressIndicator(
                                    value: animatedValue,
                                    strokeWidth: 8,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark
                                          ? (urgency == UrgencyStatus.safe
                                              ? const Color(0xFF34D399)
                                              : urgency.badgeTextColor(isDark))
                                          : urgency.color,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedOdometerText(
                                  value: currentCard.daysRemaining,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                const Text(
                                  'DAYS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),

                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: urgency.badgeBgColor(isDark),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      urgency.label,
                                      style: TextStyle(
                                        color: urgency.badgeTextColor(isDark),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (_showCelebration) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.accentEmerald,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  AnimatedOdometerText(
                                    value: currentCard.daysRemaining,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'days left',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _showCelebration
                                    ? 'Card refreshed & active!'
                                    : 'to avoid deactivation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _showCelebration
                                      ? AppTheme.accentEmerald
                                      : AppTheme.textMuted,
                                  fontWeight: _showCelebration
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Metadata 2x2 Grid
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey('meta-${currentCard.id}'),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetaItem(
                                  label: 'LAST TRANSACTION',
                                  value: dateFormat
                                      .format(currentCard.lastTransactionDate),
                                  onTap: () => _editLastTransactionDate(
                                      context, ref, currentCard),
                                ),
                              ),
                              Expanded(
                                child: _MetaItem(
                                  label: 'DEADLINE',
                                  value: dateFormat
                                      .format(currentCard.deactivationDate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MetaItem(
                                  label: 'NETWORK',
                                  value: currentCard.network,
                                ),
                              ),
                              Expanded(
                                child: _MetaItem(
                                  label: 'EXPIRES',
                                  value: currentCard.expiryDateString,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Layer 1 (On Top): Interactive Pull-Down Indicator & 3D Card Deck
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtle Apple Wallet Pull-Down Indicator
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Interactive 3D Card Deck (Horizontal 3D Slide & Vertical Pull-Down)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_pullDownOffset > 10 || _dragOffset.abs() > 10) {
                              return;
                            }
                            Navigator.push(
                              context,
                              slideUpRoute(
                                AddEditCardScreen(cardToEdit: currentCard),
                              ),
                            );
                          },
                          onPanStart: (details) {
                            if (_deckController.isAnimating ||
                                _springBackController.isAnimating) {
                              return;
                            }
                            _panStartPosition = details.localPosition;
                            _dragAxis = null;
                            _deckController.stop();
                            _springBackController.stop();
                          },
                          onPanUpdate: (details) {
                            if (_panStartPosition == null) return;
                            final totalDx =
                                details.localPosition.dx - _panStartPosition!.dx;
                            final totalDy =
                                details.localPosition.dy - _panStartPosition!.dy;

                            if (_dragAxis == null) {
                              if (totalDx.abs() > 8 || totalDy.abs() > 8) {
                                if (totalDy > 8 &&
                                    totalDy.abs() > totalDx.abs() * 1.2) {
                                  _dragAxis = Axis.vertical;
                                } else if (totalDx.abs() > 8) {
                                  _dragAxis = Axis.horizontal;
                                }
                              }
                            }

                            if (_dragAxis == Axis.vertical) {
                              if (totalDy > 0 || _pullDownOffset > 0) {
                                setState(() {
                                  _pullDownOffset =
                                      (totalDy * 0.85).clamp(0.0, 240.0);
                                });
                              }
                            } else if (_dragAxis == Axis.horizontal) {
                              double dx = totalDx;
                              if ((dx > 0 && !hasPrev) || (dx < 0 && !hasNext)) {
                                dx = dx * 0.28;
                              }
                              setState(() {
                                _dragOffset = dx;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            final velocityX =
                                details.velocity.pixelsPerSecond.dx;
                            final velocityY =
                                details.velocity.pixelsPerSecond.dy;
                            final screenWidth =
                                MediaQuery.of(context).size.width;

                            if (_dragAxis == Axis.vertical) {
                              if (_pullDownOffset > 85.0 || velocityY > 650.0) {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, currentCard.id);
                              } else if (_pullDownOffset > 0.0) {
                                _springBackAnimation = Tween<double>(
                                  begin: _pullDownOffset,
                                  end: 0.0,
                                ).animate(CurvedAnimation(
                                  parent: _springBackController,
                                  curve: Curves.easeOutBack,
                                ));
                                _springBackController.forward(from: 0.0);
                              }
                            } else if (_dragAxis == Axis.horizontal) {
                              final isFlingNext =
                                  _dragOffset < -65.0 || velocityX < -500.0;
                              final isFlingPrev =
                                  _dragOffset > 65.0 || velocityX > 500.0;

                              if (isFlingNext && hasNext && nextCard != null) {
                                _completeCardSwitch(
                                  toNext: true,
                                  targetCard: nextCard,
                                  screenWidth: screenWidth,
                                );
                              } else if (isFlingPrev &&
                                  hasPrev &&
                                  prevCard != null) {
                                _completeCardSwitch(
                                  toNext: false,
                                  targetCard: prevCard,
                                  screenWidth: screenWidth,
                                );
                              } else {
                                _springBackDeck();
                              }
                            }
                            _dragAxis = null;
                            _panStartPosition = null;
                          },
                          onPanCancel: () {
                            if (_pullDownOffset > 0) {
                              _springBackAnimation = Tween<double>(
                                begin: _pullDownOffset,
                                end: 0.0,
                              ).animate(CurvedAnimation(
                                parent: _springBackController,
                                curve: Curves.easeOutBack,
                              ));
                              _springBackController.forward(from: 0.0);
                            }
                            if (_dragOffset != 0) {
                              _springBackDeck();
                            }
                            _dragAxis = null;
                            _panStartPosition = null;
                          },
                          child: Transform.translate(
                            offset: Offset(0.0, _pullDownOffset),
                            child: Transform.scale(
                              scale: (1.0 - (_pullDownOffset / 1000))
                                  .clamp(0.88, 1.0),
                              child: _build3DCardDeck(
                                context: context,
                                currentCard: currentCard,
                                prevCard: prevCard,
                                nextCard: nextCard,
                                hasPrev: hasPrev,
                                hasNext: hasNext,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          SafeArea(
            top: false,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Action Button: "Mark Transaction Today"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isResetting
                          ? null
                          : () async {
                              setState(() {
                                _isResetting = true;
                                _showCelebration = true;
                              });
                              HapticFeedback.heavyImpact();
                              await Future.delayed(
                                  const Duration(milliseconds: 140));
                              HapticFeedback.lightImpact();

                              await ref
                                  .read(cardNotifierProvider.notifier)
                                  .markUsedToday(currentCard.id);

                              await Future.delayed(
                                  const Duration(milliseconds: 950));
                              if (!context.mounted) return;
                              Navigator.pop(context, currentCard.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${currentCard.cardName} reset for ${currentCard.deactivationPeriodDays} days!'),
                                  backgroundColor: AppTheme.accentEmerald,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isResetting
                            ? AppTheme.accentEmerald
                            : (isDark
                                ? AppTheme.primaryAccentDark
                                : AppTheme.primaryNavy),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isResetting
                            ? const Row(
                                key: ValueKey('resetting'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reset Complete!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Mark Transaction Today',
                                key: const ValueKey('idle'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Actions Row: Solid Edit & Delete Buttons (No Icons)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                slideUpRoute(
                                  AddEditCardScreen(cardToEdit: currentCard),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _confirmDelete(context, ref, currentCard),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentRose,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _editLastTransactionDate(
    BuildContext context,
    WidgetRef ref,
    CreditCard currentCard,
  ) async {
    final now = DateTime.now();
    final initialDate = currentCard.lastTransactionDate.isAfter(now)
        ? now
        : currentCard.lastTransactionDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate != null) {
      await ref
          .read(cardNotifierProvider.notifier)
          .updateTransactionDate(currentCard.id, pickedDate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Updated last transaction date for ${currentCard.cardName}'),
            backgroundColor: AppTheme.accentEmerald,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CreditCard targetCard) async {
    final confirm = await showDeleteConfirmationDialog(
      context: context,
      cardName: targetCard.cardName,
    );

    if (confirm == true) {
      ref.read(cardNotifierProvider.notifier).deleteCard(targetCard.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _completeCardSwitch({
    required bool toNext,
    required CreditCard targetCard,
    required double screenWidth,
  }) {
    HapticFeedback.lightImpact();
    final targetEndOffset = toNext ? -screenWidth : screenWidth;

    _deckAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetEndOffset,
    ).animate(CurvedAnimation(
      parent: _deckController,
      curve: Curves.easeOutCubic,
    ));

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _deckController.removeStatusListener(statusListener);
        if (mounted) {
          setState(() {
            _currentCardId = targetCard.id;
            _dragOffset = 0.0;
            _deckAnimation = const AlwaysStoppedAnimation<double>(0.0);
            _deckController.reset();
          });
        }
      }
    }

    _deckController.addStatusListener(statusListener);
    _deckController.forward(from: 0.0);
  }

  void _springBackDeck() {
    if (_dragOffset.abs() > 20) {
      HapticFeedback.selectionClick();
    }
    _deckAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _deckController,
      curve: Curves.easeOutBack,
    ));

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _deckController.removeStatusListener(statusListener);
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _deckAnimation = const AlwaysStoppedAnimation<double>(0.0);
            _deckController.reset();
          });
        }
      }
    }

    _deckController.addStatusListener(statusListener);
    _deckController.forward(from: 0.0);
  }

  Widget _build3DCardDeck({
    required BuildContext context,
    required CreditCard currentCard,
    required CreditCard? prevCard,
    required CreditCard? nextCard,
    required bool hasPrev,
    required bool hasNext,
    required bool isDark,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dragFraction = (_dragOffset / screenWidth).clamp(-1.0, 1.0);
    final absOffset = _dragOffset.abs();
    final switchProgress = (absOffset / 200.0).clamp(0.0, 1.0);

    // Determine which background card to display in the 3D depth stack
    final CreditCard? backgroundCard = _dragOffset < 0
        ? nextCard
        : (_dragOffset > 0 ? prevCard : (hasNext ? nextCard : null));

    // Background card transforms (emerging from 3D depth)
    final bgScale = 0.92 + (0.08 * switchProgress);
    final bgOpacity = _dragOffset == 0.0
        ? (hasNext ? (isDark ? 0.20 : 0.28) : 0.0)
        : (0.35 + 0.65 * switchProgress).clamp(0.0, 1.0);
    final bgTranslateY = (1.0 - switchProgress) * 10.0;
    final bgAngleY = _dragOffset < 0
        ? (1.0 - switchProgress) * 0.12
        : (_dragOffset > 0 ? -(1.0 - switchProgress) * 0.12 : 0.0);

    final bgMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(0.0, bgTranslateY, -35.0 * (1.0 - switchProgress), 1.0)
      ..rotateY(bgAngleY);

    // Front card transforms (interactive 3D perspective rotation, wrist tilt, tension scale)
    final frontAngleY = -dragFraction * 0.70;
    final frontAngleZ = dragFraction * 0.12;
    final frontScale =
        (1.0 - (absOffset / screenWidth) * 0.08).clamp(0.92, 1.0);
    final frontOpacity =
        absOffset > 70 ? (1.0 - (absOffset - 70) / (screenWidth * 0.7)).clamp(0.0, 1.0) : 1.0;

    final frontMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(_dragOffset, 0.0, 0.0, 1.0)
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
                  enableTilt: _dragOffset == 0.0 && _pullDownOffset == 0.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _MetaItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_outlined,
                size: 11,
                color: AppTheme.textMuted,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
