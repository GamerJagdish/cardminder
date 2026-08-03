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

  Color badgeBgColor(bool isDark) {
    if (isDark) {
      switch (this) {
        case UrgencyStatus.safe:
          return const Color(0xFF064E3B); // Dark emerald container
        case UrgencyStatus.warning:
          return const Color(0xFF78350F); // Dark amber container
        case UrgencyStatus.critical:
          return const Color(0xFF7F1D1D); // Dark red container
        case UrgencyStatus.expired:
          return const Color(0xFF1E293B); // Dark slate container
      }
    }
    return bgLightColor;
  }

  Color badgeTextColor(bool isDark) {
    if (isDark) {
      switch (this) {
        case UrgencyStatus.safe:
          return const Color(0xFF34D399); // Vibrant emerald green
        case UrgencyStatus.warning:
          return const Color(0xFFFDE047); // Vibrant bright yellow text
        case UrgencyStatus.critical:
          return const Color(0xFFFCA5A5); // Vibrant bright rose text
        case UrgencyStatus.expired:
          return const Color(0xFF94A3B8); // Slate grey text
      }
    }
    return color;
  }

  Color get bgLightColor {
    switch (this) {
      case UrgencyStatus.safe:
        return const Color(0xFFDCFCE7); // Light green badge bg
      case UrgencyStatus.warning:
        return const Color(0xFFFEF3C7); // Light amber badge bg
      case UrgencyStatus.critical:
        return const Color(0xFFFEE2E2); // Light red badge bg
      case UrgencyStatus.expired:
        return const Color(0xFFF3F4F6); // Light gray badge bg
    }
  }

  String get label {
    switch (this) {
      case UrgencyStatus.safe:
        return 'SAFE';
      case UrgencyStatus.warning:
        return 'WARNING';
      case UrgencyStatus.critical:
        return 'URGENT';
      case UrgencyStatus.expired:
        return 'EXPIRED';
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
  final String cardType; // e.g. "Debit Card", "Credit Card"
  final String network; // Visa, Mastercard, Amex, Discover
  final String expiryMonth; // e.g. "12"
  final String expiryYear; // e.g. "28"
  final int deactivationPeriodDays; // Default: 365 days (1 year)

  CreditCard({
    required this.id,
    required this.cardName,
    this.lastFourDigits,
    required this.lastTransactionDate,
    this.colorIndex = 0,
    this.bankName,
    this.cardType = 'Credit Card',
    this.network = 'Visa',
    this.expiryMonth = '12',
    this.expiryYear = '28',
    this.deactivationPeriodDays = 365,
  });

  /// Deactivation date is [deactivationPeriodDays] after the last transaction date
  DateTime get deactivationDate =>
      lastTransactionDate.add(Duration(days: deactivationPeriodDays));

  /// Calculates number of days remaining until deactivation deadline
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(
      lastTransactionDate.year,
      lastTransactionDate.month,
      lastTransactionDate.day,
    );
    final deadline = txDate.add(Duration(days: deactivationPeriodDays));
    return deadline.difference(today).inDays;
  }

  /// Percentage elapsed of the deactivation period (0.0 = just used, 1.0 = period passed)
  double get elapsedProgress {
    final remaining = daysRemaining;
    if (remaining <= 0) return 1.0;
    if (remaining >= deactivationPeriodDays) return 0.0;
    return (deactivationPeriodDays - remaining) / deactivationPeriodDays.toDouble();
  }

  UrgencyStatus get status {
    final remaining = daysRemaining;
    if (remaining <= 0) return UrgencyStatus.expired;

    final criticalThreshold =
        (deactivationPeriodDays * 0.1).round().clamp(7, 30);
    final warningThreshold =
        (deactivationPeriodDays * 0.25).round().clamp(15, 90);

    if (remaining <= criticalThreshold) return UrgencyStatus.critical;
    if (remaining <= warningThreshold) return UrgencyStatus.warning;
    return UrgencyStatus.safe;
  }

  String get expiryDateString => '$expiryMonth/$expiryYear';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardName': cardName,
      'lastFourDigits': lastFourDigits,
      'lastTransactionDate': lastTransactionDate.toIso8601String(),
      'colorIndex': colorIndex,
      'bankName': bankName,
      'cardType': cardType,
      'network': network,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'deactivationPeriodDays': deactivationPeriodDays,
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
      cardType: (json['cardType'] as String?) ?? 'Debit Card',
      network: (json['network'] as String?) ?? 'Visa',
      expiryMonth: (json['expiryMonth'] as String?) ?? '12',
      expiryYear: (json['expiryYear'] as String?) ?? '28',
      deactivationPeriodDays: (json['deactivationPeriodDays'] as int?) ?? 365,
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
    String? network,
    String? expiryMonth,
    String? expiryYear,
    int? deactivationPeriodDays,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      colorIndex: colorIndex ?? this.colorIndex,
      bankName: bankName ?? this.bankName,
      cardType: cardType ?? this.cardType,
      network: network ?? this.network,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      deactivationPeriodDays:
          deactivationPeriodDays ?? this.deactivationPeriodDays,
    );
  }
}
