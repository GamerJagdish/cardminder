import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/credit_card.dart';

class StorageService {
  static const String _boxName = 'cards_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  List<CreditCard> loadCards() {
    final cards = <CreditCard>[];
    for (var value in _box.values) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(value);
        cards.add(CreditCard.fromJson(jsonMap));
      } catch (e) {
        // Skip corrupted records
      }
    }
    // Sort cards by days remaining ascending (most urgent first)
    cards.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return cards;
  }

  Future<void> saveCard(CreditCard card) async {
    final jsonString = jsonEncode(card.toJson());
    await _box.put(card.id, jsonString);
  }

  Future<void> deleteCard(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
