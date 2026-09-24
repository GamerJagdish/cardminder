import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../services/notification_log_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../services/widget_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/home/home_bottom_nav_bar.dart';
import '../widgets/home/home_view.dart';
import 'card_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentPage = 0;
  int _selectedTab = 0;
  late PageController _pageController;
  late ScrollController _homeScrollController;
  StreamSubscription<Uri?>? _widgetClickSubscription;
  Timer? _deferredTasksTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
    );
    _homeScrollController = ScrollController();
    _initWidgetLaunchHandling();
    _initDeferredBackgroundTasks();
  }

  void _initDeferredBackgroundTasks() {
    // Allow initial frames, layout, and entrance animations to settle
    // smoothly before executing non-urgent background maintenance.
    _deferredTasksTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final cards = ref.read(cardNotifierProvider).cards;

      try {
        await ref
            .read(notificationLogNotifierProvider.notifier)
            .updateLogsForCards(cards);
      } catch (_) {}

      if (!mounted) return;

      try {
        await WidgetService.updateHomeWidget(cards);
        await NotificationService.requestPermissions();
        await NotificationService.syncCardNotifications(cards);
        await UpdateService.cleanupOldApks();
      } catch (_) {}
    });
  }

  void _initWidgetLaunchHandling() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleWidgetLaunchUri(uri);
        });
      }
    });

    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
      _handleWidgetLaunchUri(uri);
    });
  }

  void _handleWidgetLaunchUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final cardId = uri.queryParameters['id'] ??
        (uri.host == 'card' && uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null);
    final cardName = uri.queryParameters['name'];
    final cardDigits = uri.queryParameters['digits'];

    final cards = ref.read(cardNotifierProvider).cards;
    CreditCard? targetCard;
    if (cardId != null && cardId.isNotEmpty) {
      targetCard = cards.where((c) => c.id == cardId).firstOrNull;
    }
    if (targetCard == null && (cardDigits != null || cardName != null)) {
      targetCard = cards.where((c) {
        if (cardDigits != null &&
            cardDigits.isNotEmpty &&
            c.lastFourDigits == cardDigits) {
          return true;
        }
        if (cardName != null &&
            cardName.isNotEmpty &&
            c.cardName.toLowerCase() == cardName.toLowerCase()) {
          return true;
        }
        return false;
      }).firstOrNull;
    }

    if (targetCard != null) {
      _syncSelectedCard(targetCard.id);
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.push<String?>(
        context,
        slideUpRoute(
          CardDetailsScreen(card: targetCard),
        ),
      ).then((closedCardId) {
        _syncSelectedCard(closedCardId);
      });
    }
  }

  @override
  void dispose() {
    _deferredTasksTimer?.cancel();
    _widgetClickSubscription?.cancel();
    _pageController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _syncSelectedCard(String? closedCardId) {
    if (closedCardId == null || !mounted) return;
    final currentCards = ref.read(cardNotifierProvider).filteredCards;
    final targetIdx = currentCards.indexWhere((c) => c.id == closedCardId);
    if (targetIdx != -1) {
      if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
        _homeScrollController.jumpTo(0.0);
      }
      setState(() => _currentPage = targetIdx);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIdx);
      }
    }
  }

  void _onCardAdded(String cardId) {
    if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
      _homeScrollController.jumpTo(0.0);
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          HomeView(
            scrollController: _homeScrollController,
            pageController: _pageController,
            isInteractive: true,
            showBottomNavBar: false,
            isActive: _selectedTab == 0,
            onCardAdded: _onCardAdded,
          ),
          const SettingsScreen(),
        ],
      ),
      // Custom Floating Bottom Navigation Bar (Mathematically Centered 3-Column Grid)
      bottomNavigationBar: RepaintBoundary(
        child: HomeBottomNavBar(
          selectedTab: _selectedTab,
          onTabSelected: (tab) => setState(() => _selectedTab = tab),
          onHomeReselected: () {
            if (_homeScrollController.hasClients &&
                _homeScrollController.offset > 0) {
              _homeScrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            }
          },
          onCardAdded: _onCardAdded,
        ),
      ),
    );
  }
}
