import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/transaction.dart';
import 'package:momo_wallet/wallet.dart';

// Oldest first, same as the old sample data.
const samples = [
  Transaction(id: '1', description: 'Received from Aline', amount: 3000, direction: Direction.incoming),
  Transaction(id: '2', description: 'Sent to 0788123456', amount: 1500, direction: Direction.outgoing),
  Transaction(id: '3', description: 'Cash out', amount: 800, direction: Direction.outgoing),
  Transaction(id: '4', description: 'Received from Jean', amount: 2500, direction: Direction.incoming),
  Transaction(id: '5', description: 'Sent to 0791234567', amount: 200, direction: Direction.outgoing),
];

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

  test('wallet calculations', () {
    final w = Wallet(samples);
    expect(w.balance, 13000);
    expect(w.totalIn, 5500);
    expect(w.totalOut, 2500);
    expect(w.lowestBalance, 10000);
    expect(w.newestFirst.first.description, 'Sent to 0791234567');
  });

  test('wallet rejects bad requests', () async {
    final w = Wallet(samples);
    expect(await w.send('0788123456', 50), isNotNull);
    expect(await w.send('0721234567', 500), isNotNull);
    expect(await w.cashOut(1000000), 'Insufficient balance');
    expect(await w.cashOut(250), isNotNull);
    expect(await w.delete('999'), 'Transaction not found');
    // Deleting the opening income would push the balance below 0 here.
    final tight = Wallet(const [
      Transaction(id: 'a', description: 'In', amount: 100, direction: Direction.incoming),
      Transaction(id: 'b', description: 'Out', amount: 10100, direction: Direction.outgoing),
    ]);
    expect(await tight.delete('a'), isNotNull);
  });
}
