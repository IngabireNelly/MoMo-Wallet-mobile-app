import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/transaction.dart';
import 'package:momo_wallet/wallet.dart';

void main() {
  test('phone rules', () {
    expect(checkPhone('0721234567'), isNotNull);
    expect(checkPhone('0788123456'), isNull);
  });

  test('amount rules', () {
    expect(parseWholeNumber('5k'), isNull);
    expect(parseWholeNumber('0'), isNull);
    expect(parseWholeNumber('-200'), isNull);
    expect(parseWholeNumber('5000'), 5000);
  });

  test('cash out notes', () {
    expect(splitIntoNotes(23700), {5000: 4, 2000: 1, 1000: 1, 500: 1, 100: 2});
    expect(splitIntoNotes(250), isNull);
  });

  test('wallet rules', () {
    final w = Wallet();
    expect(w.balance, 13000);
    expect(w.lowestBalance, 10000);
    expect(w.send('0788123456', 50), isNotNull);
    expect(w.cashOut(1000000), 'Insufficient balance');
    expect(w.send('0788123456', 500), isNull);
    expect(w.balance, 12500);
    expect(w.newestFirst.first.description, 'Sent to 0788123456');
  });
}