import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'add_edit_card_screen.dart';
import 'card_details/widgets/card_3d_deck.dart';
import 'card_details/widgets/card_countdown_banner.dart';
import 'card_details/widgets/card_details_action_bar.dart';
import 'card_details/widgets/card_meta_grid.dart';

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
                      CardCountdownBanner(
                        card: currentCard,
                        showCelebration: _showCelebration,
                      ),

                      const SizedBox(height: 16),

                      // Metadata 2x2 Grid
                      CardMetaGrid(
                        card: currentCard,
                        onEditLastTransactionDate: () =>
                            _editLastTransactionDate(context, ref, currentCard),
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
                              child: Card3DDeck(
                                currentCard: currentCard,
                                prevCard: prevCard,
                                nextCard: nextCard,
                                hasPrev: hasPrev,
                                hasNext: hasNext,
                                dragOffset: _dragOffset,
                                pullDownOffset: _pullDownOffset,
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
          CardDetailsActionBar(
            card: currentCard,
            isResetting: _isResetting,
            onMarkUsedToday: () async {
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
            onEdit: () {
              Navigator.push(
                context,
                slideUpRoute(
                  AddEditCardScreen(cardToEdit: currentCard),
                ),
              );
            },
            onDelete: () => _confirmDelete(context, ref, currentCard),
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
}

