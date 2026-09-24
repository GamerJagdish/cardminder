import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/notification_log.dart';

class NotificationLogService {
  static const String _boxName = 'notification_logs_box';
  final _uuid = const Uuid();

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  List<NotificationLog> loadLogs() {
    final logs = <NotificationLog>[];
    for (var value in _box.values) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(value);
        logs.add(NotificationLog.fromJson(jsonMap));
      } catch (e) {
        // Skip invalid records
      }
    }
    // Sort latest first
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<bool> generateLogsForCards(List<CreditCard> cards) async {
    final existingLogs = loadLogs();
    final now = DateTime.now();
    bool hasNew = false;

    for (var card in cards) {
      final days = card.daysRemaining;
      if (days <= 30) {
        // Check if log already exists for this card & threshold
        final hasLog = existingLogs.any((l) =>
            l.cardId == card.id &&
            l.daysRemaining == days &&
            l.timestamp.day == now.day &&
            l.timestamp.month == now.month);

        if (!hasLog) {
          final newLog = NotificationLog(
            id: _uuid.v4(),
            cardId: card.id,
            cardName: card.cardName,
            message:
                '${card.cardName} has $days day(s) remaining before 365-day deactivation!',
            timestamp: now,
            daysRemaining: days,
            isRead: false,
          );
          await saveLog(newLog);
          hasNew = true;
        }
      }
    }
    return hasNew;
  }

  Future<void> saveLog(NotificationLog log) async {
    final jsonStr = jsonEncode(log.toJson());
    await _box.put(log.id, jsonStr);
  }

  Future<void> setReadStatus(String id, bool isRead) async {
    final raw = _box.get(id);
    if (raw != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(raw);
        final log = NotificationLog.fromJson(jsonMap);
        final updated = log.copyWith(isRead: isRead);
        await saveLog(updated);
      } catch (_) {}
    }
  }

  Future<void> toggleReadStatus(String id) async {
    final raw = _box.get(id);
    if (raw != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(raw);
        final log = NotificationLog.fromJson(jsonMap);
        final updated = log.copyWith(isRead: !log.isRead);
        await saveLog(updated);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    final logs = loadLogs();
    for (var log in logs) {
      if (!log.isRead) {
        final updated = log.copyWith(isRead: true);
        await saveLog(updated);
      }
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}

class NotificationLogNotifier extends Notifier<List<NotificationLog>> {
  late final NotificationLogService _service;

  @override
  List<NotificationLog> build() {
    _service = ref.watch(notificationLogServiceProvider);
    return _service.loadLogs();
  }

  void loadLogs() {
    state = _service.loadLogs();
  }

  Future<void> updateLogsForCards(List<CreditCard> cards) async {
    final hasNew = await _service.generateLogsForCards(cards);
    if (hasNew) {
      loadLogs();
    }
  }

  Future<void> setReadStatus(String id, bool isRead) async {
    await _service.setReadStatus(id, isRead);
    loadLogs();
  }

  Future<void> toggleReadStatus(String id) async {
    await _service.toggleReadStatus(id);
    loadLogs();
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    loadLogs();
  }

  Future<void> clearLogs() async {
    await _service.clearAll();
    loadLogs();
  }

  int get unreadCount => state.where((l) => !l.isRead).length;
}

final notificationLogServiceProvider = Provider<NotificationLogService>((ref) {
  return NotificationLogService();
});

final notificationLogNotifierProvider =
    NotifierProvider<NotificationLogNotifier, List<NotificationLog>>(
        NotificationLogNotifier.new);
