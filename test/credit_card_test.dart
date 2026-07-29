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
  });
}
