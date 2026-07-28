import 'package:flutter/material.dart';

enum UrgencyStatus {
  safe,
  warning,
  critical,
  expired;

  Color get color {
    switch (this) {
      case UrgencyStatus.safe:
        return const Color(0xFF10B981); // Emerald green
      case UrgencyStatus.warning:
        return const Color(0xFFF59E0B); // Amber / Gold
      case UrgencyStatus.critical:
        return const Color(0xFFEF4444); // Crimson red
      case UrgencyStatus.expired:
        return const Color(0xFF6B7280); // Muted gray
    }
  }

  String get label {
    switch (this) {
      case UrgencyStatus.safe:
        return 'Safe';
      case UrgencyStatus.warning:
        return 'Needs Attention';
      case UrgencyStatus.critical:
        return 'Urgent';
      case UrgencyStatus.expired:
        return 'Expired / Inactive';
    }
  }
}

class CreditCard {
  final String id;
  final String cardName;
  final String? lastFourDigits;
  final DateTime lastTransactionDate;
  final int colorIndex;
  final String? bankName;
  final String? cardType; // Visa, Mastercard, Amex, RuPay, etc.

  CreditCard({
    required this.id,
    required this.cardName,
    this.lastFourDigits,
    required this.lastTransactionDate,
    this.colorIndex = 0,
    this.bankName,
    this.cardType,
  });

  /// Expiry date is 365 days after the last transaction date
  DateTime get deactivationDate =>
      lastTransactionDate.add(const Duration(days: 365));

  /// Calculates number of days remaining until 365-day deadline
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(
      lastTransactionDate.year,
      lastTransactionDate.month,
      lastTransactionDate.day,
    );
    final deadline = txDate.add(const Duration(days: 365));
    return deadline.difference(today).inDays;
  }

  /// Percentage elapsed of the 365 days (0.0 = just used, 1.0 = 365 days passed)
  double get elapsedProgress {
    final remaining = daysRemaining;
    if (remaining <= 0) return 1.0;
    if (remaining >= 365) return 0.0;
    return (365 - remaining) / 365.0;
  }

  UrgencyStatus get status {
    final remaining = daysRemaining;
    if (remaining <= 0) return UrgencyStatus.expired;
    if (remaining <= 30) return UrgencyStatus.critical;
    if (remaining <= 90) return UrgencyStatus.warning;
    return UrgencyStatus.safe;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardName': cardName,
      'lastFourDigits': lastFourDigits,
      'lastTransactionDate': lastTransactionDate.toIso8601String(),
      'colorIndex': colorIndex,
      'bankName': bankName,
      'cardType': cardType,
    };
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as String,
      cardName: json['cardName'] as String,
      lastFourDigits: json['lastFourDigits'] as String?,
      lastTransactionDate: DateTime.parse(json['lastTransactionDate'] as String),
      colorIndex: (json['colorIndex'] as int?) ?? 0,
      bankName: json['bankName'] as String?,
      cardType: json['cardType'] as String?,
    );
  }

  CreditCard copyWith({
    String? id,
    String? cardName,
    String? lastFourDigits,
    DateTime? lastTransactionDate,
    int? colorIndex,
    String? bankName,
    String? cardType,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      colorIndex: colorIndex ?? this.colorIndex,
      bankName: bankName ?? this.bankName,
      cardType: cardType ?? this.cardType,
    );
  }
}
