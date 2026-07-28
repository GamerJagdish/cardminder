import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';

void main() {
  group('CreditCard Model Calculations Test', () {
    test('Calculates exactly 365 days remaining when last transaction was today', () {
      final now = DateTime.now();
      final card = CreditCard(
        id: '1',
        cardName: 'HDFC Regalia',
        lastFourDigits: '1234',
        lastTransactionDate: now,
      );

      expect(card.daysRemaining, equals(365));
      expect(card.status, equals(UrgencyStatus.safe));
      expect(card.elapsedProgress, equals(0.0));
    });

    test('Calculates remaining days correctly for past date', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 350));
      final card = CreditCard(
        id: '2',
        cardName: 'ICICI Sapphiro',
        lastFourDigits: '9999',
        lastTransactionDate: pastDate,
      );

      expect(card.daysRemaining, equals(15));
      expect(card.status, equals(UrgencyStatus.critical));
    });

    test('Identifies expired card when transaction was >365 days ago', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 370));
      final card = CreditCard(
        id: '3',
        cardName: 'Amex Platinum',
        lastTransactionDate: expiredDate,
      );

      expect(card.daysRemaining <= 0, isTrue);
      expect(card.status, equals(UrgencyStatus.expired));
      expect(card.elapsedProgress, equals(1.0));
    });
  });
}
