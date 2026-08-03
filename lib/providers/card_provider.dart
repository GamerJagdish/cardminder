import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';

enum FilterType { all, actionRequired, safe }

enum SortMode { urgency, custom }

class CardState {
  final List<CreditCard> cards;
  final bool isLoading;
  final String searchQuery;
  final FilterType filter;
  final SortMode sortMode;

  CardState({
    required this.cards,
    this.isLoading = false,
    this.searchQuery = '',
    this.filter = FilterType.all,
    this.sortMode = SortMode.urgency,
  });

  List<CreditCard> get filteredCards {
    final list = cards.where((card) {
      // Apply Search Filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = card.cardName.toLowerCase().contains(query);
        final matchesDigits = card.lastFourDigits?.contains(query) ?? false;
        final matchesBank = card.bankName?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesDigits && !matchesBank) return false;
      }

      // Apply Urgency Category Filter
      switch (filter) {
        case FilterType.actionRequired:
          return card.daysRemaining <= 30;
        case FilterType.safe:
          return card.daysRemaining > 30;
        case FilterType.all:
          return true;
      }
    }).toList();

    if (sortMode == SortMode.urgency) {
      list.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    }
    return list;
  }

  int get totalCards => cards.length;
  int get actionRequiredCount => cards.where((c) => c.daysRemaining <= 30).length;
  int get safeCount => cards.where((c) => c.daysRemaining > 30).length;

  CardState copyWith({
    List<CreditCard>? cards,
    bool? isLoading,
    String? searchQuery,
    FilterType? filter,
    SortMode? sortMode,
  }) {
    return CardState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

class CardNotifier extends StateNotifier<CardState> {
  final StorageService _storageService;
  final _uuid = const Uuid();

  CardNotifier(this._storageService) : super(CardState(cards: [], isLoading: true)) {
    _loadCards();
  }

  void reloadCards() {
    _loadCards();
  }

  void _loadCards() {
    final loaded = _storageService.loadCards();
    state = state.copyWith(cards: loaded, isLoading: false);
    _syncExternalServices(loaded);
  }

  Future<void> addCard({
    required String cardName,
    String? lastFourDigits,
    required DateTime lastTransactionDate,
    int colorIndex = 0,
    String? bankName,
    String? cardType,
    int deactivationPeriodDays = 365,
  }) async {
    final newCard = CreditCard(
      id: _uuid.v4(),
      cardName: cardName,
      lastFourDigits: lastFourDigits,
      lastTransactionDate: lastTransactionDate,
      colorIndex: colorIndex,
      bankName: bankName,
      cardType: cardType ?? 'Debit Card',
      deactivationPeriodDays: deactivationPeriodDays,
    );

    await _storageService.saveCard(newCard);
    final updatedList = _storageService.loadCards();
    state = state.copyWith(cards: updatedList);
    _syncExternalServices(updatedList);
  }

  Future<void> updateCard(CreditCard card) async {
    await _storageService.saveCard(card);
    final updatedList = _storageService.loadCards();
    state = state.copyWith(cards: updatedList);
    _syncExternalServices(updatedList);
  }

  Future<void> markUsedToday(String cardId) async {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    if (index != -1) {
      final updatedCard = state.cards[index].copyWith(
        lastTransactionDate: DateTime.now(),
      );
      await updateCard(updatedCard);
    }
  }

  Future<void> updateTransactionDate(String cardId, DateTime newDate) async {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    if (index != -1) {
      final updatedCard = state.cards[index].copyWith(
        lastTransactionDate: newDate,
      );
      await updateCard(updatedCard);
    }
  }

  Future<void> deleteCard(String cardId) async {
    await _storageService.deleteCard(cardId);
    final updatedList = _storageService.loadCards();
    state = state.copyWith(cards: updatedList);
    _syncExternalServices(updatedList);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(FilterType filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> reorderCards(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final currentList = List<CreditCard>.from(state.filteredCards);
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);

    state = state.copyWith(cards: currentList, sortMode: SortMode.custom);
    await _storageService.saveAllCards(currentList);
    _syncExternalServices(currentList);
  }

  void toggleSortMode() {
    final nextMode = state.sortMode == SortMode.urgency
        ? SortMode.custom
        : SortMode.urgency;
    state = state.copyWith(sortMode: nextMode);
  }

  void _syncExternalServices(List<CreditCard> cards) {
    WidgetService.updateHomeWidget(cards);
    NotificationService.syncCardNotifications(cards);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final cardNotifierProvider =
    StateNotifierProvider<CardNotifier, CardState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CardNotifier(storage);
});
