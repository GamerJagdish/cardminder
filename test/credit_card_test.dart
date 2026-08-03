import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';

void main() {
  group('CreditCard Model Calculations Test', () {
    test('Calculates exactly 365 days remaining when last transaction was today', () {
      final now = DateTime.now();
      final card = CreditCard(
        id: '1',
        cardName: 'Citi Rewards',
        lastFourDigits: '7712',
        lastTransactionDate: now,
        network: 'Mastercard',
        expiryMonth: '12',
        expiryYear: '28',
      );

      expect(card.daysRemaining, equals(365));
      expect(card.status, equals(UrgencyStatus.safe));
      expect(card.elapsedProgress, equals(0.0));
      expect(card.expiryDateString, equals('12/28'));
    });

    test('Calculates remaining days correctly for past date', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 350));
      final card = CreditCard(
        id: '2',
        cardName: 'Swiggy HDFC',
        lastFourDigits: '4821',
        lastTransactionDate: pastDate,
        network: 'Visa',
      );

      expect(card.daysRemaining, equals(15));
      expect(card.status, equals(UrgencyStatus.critical));
    });

    test('Calculates remaining days correctly for custom deactivation period (90 days)', () {
      final now = DateTime.now();
      final card = CreditCard(
        id: '3',
        cardName: 'Amex Platinum',
        lastTransactionDate: now.subtract(const Duration(days: 60)),
        deactivationPeriodDays: 90,
      );

      expect(card.daysRemaining, equals(30));
      expect(card.deactivationPeriodDays, equals(90));
      expect(card.deactivationDate.difference(DateTime(now.year, now.month, now.day)).inDays, equals(30));
    });

    test('Successfully restores old card JSON without deactivationPeriodDays and defaults to 365', () {
      final oldJson = {
        'id': 'old-card-1',
        'cardName': 'Old Card',
        'lastFourDigits': '1234',
        'lastTransactionDate': DateTime.now().toIso8601String(),
        'colorIndex': 0,
        'bankName': 'HDFC',
        'cardType': 'Credit Card',
        'network': 'Visa',
        'expiryMonth': '10',
        'expiryYear': '27',
      };

      final restoredCard = CreditCard.fromJson(oldJson);
      expect(restoredCard.deactivationPeriodDays, equals(365));
      expect(restoredCard.cardName, equals('Old Card'));
    });
  });
}
