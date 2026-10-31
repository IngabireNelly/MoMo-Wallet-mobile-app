import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'transaction.dart';

const List<int> noteValues = [5000, 2000, 1000, 500, 100];

// ---------- Input checks: return an error message, or null if OK ----------

String? checkPhone(String phone) {
  final p = phone.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(p)) {
    return 'Phone number must be exactly 10 digits';
  }
  if (!p.startsWith('078') && !p.startsWith('079')) {
    return 'Phone number must start with 078 or 079';
  }
  return null;
}

// Returns the whole number, or null if the text is not a number above 0.
int? parseWholeNumber(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value <= 0) return null;
  return value;
}

// Splits an amount into the agent's notes, biggest first.
// Returns null if the amount is not a positive multiple of 100.
Map<int, int>? splitIntoNotes(int amount) {
  if (amount <= 0 || amount % 100 != 0) return null;
  var remaining = amount;
  final result = <int, int>{};
  for (final note in noteValues) {
    final count = remaining ~/ note;
    if (count > 0) {
      result[note] = count;
      remaining -= count * note;
    }
  }
  return result;
}

// ---------- The wallet: holds the history and enforces the rules ----------

int _apply(int balance, Transaction t) =>
    t.direction == Direction.incoming ? balance + t.amount : balance - t.amount;

int _balanceOf(List<Transaction> items) {
  var balance = Wallet.openingBalance;
  for (final t in items) {
    balance = _apply(balance, t);
  }
  return balance;
}

// The lowest balance ever reached. It starts at the opening balance, not 0.
int _lowestOf(List<Transaction> items) {
  var balance = Wallet.openingBalance;
  var lowest = balance;
  for (final t in items) {
    balance = _apply(balance, t);
    if (balance < lowest) lowest = balance;
  }
  return lowest;
}

class Wallet {
  Wallet(this._history);

  static const int openingBalance = 10000;
  static Transaction? _lastDeleted;

  // Oldest first. The screen shows newestFirst.
  final List<Transaction> _history;

  List<Transaction> get newestFirst => _history.reversed.toList();

  int get balance => _balanceOf(_history);

  int get totalIn => _history
      .where((t) => t.direction == Direction.incoming)
      .fold(0, (total, t) => total + t.amount);

  int get totalOut => _history
      .where((t) => t.direction == Direction.outgoing)
      .fold(0, (total, t) => total + t.amount);

  int get lowestBalance => _lowestOf(_history);

  Future<void> _add(String description, int amount, Direction direction) {
    final t = Transaction(
        description: description, amount: amount, direction: direction);
    return myTransactions().add({
      ...t.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> addIncoming(int amount, String description) async {
    if (description.trim().isEmpty) return 'Description cannot be empty';
    if (amount <= 0) return 'Amount must be a whole number above 0';
    await _add(description.trim(), amount, Direction.incoming);
    return null;
  }

  Future<String?> send(String phone, int amount) async {
    final phoneError = checkPhone(phone);
    if (phoneError != null) return phoneError;
    if (amount < 100) return 'Send at least 100 RWF';
    if (amount > balance) return 'Insufficient balance';
    await _add('Sent to ${phone.trim()}', amount, Direction.outgoing);
    return null;
  }

  Future<String?> cashOut(int amount) async {
    if (splitIntoNotes(amount) == null) {
      return 'Amount must be a multiple of 100 (for example 500 or 1000)';
    }
    if (amount > balance) return 'Insufficient balance';
    await _add('Cash out', amount, Direction.outgoing);
    return null;
  }

  Future<String?> delete(String id) async {
    final position = _history.indexWhere((t) => t.id == id);
    if (position == -1) return 'Transaction not found';

    final withoutIt = [..._history]..removeAt(position);
    if (_lowestOf(withoutIt) < 0) {
      return 'Cannot delete: the balance would go below 0';
    }

    _lastDeleted = _history[position];
    await myTransactions().doc(id).delete();
    return null;
  }

  // Undo = write the same data back with doc(id).set(...)
  Future<void> undoDelete() async {
    final t = _lastDeleted;
    if (t == null) return;
    _lastDeleted = null;
    await myTransactions().doc(t.id).set({
      ...t.toMap(),
      'createdAt': t.createdAt != null
          ? Timestamp.fromDate(t.createdAt!)
          : FieldValue.serverTimestamp(),
    });
  }
}
