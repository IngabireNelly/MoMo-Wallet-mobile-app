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
  static const int openingBalance = 10000;

  // Stored oldest first. The screen shows newestFirst.
  final List<Transaction> _history = [
    const Transaction(id: 1, description: 'Received from Aline', amount: 3000, direction: Direction.incoming),
    const Transaction(id: 2, description: 'Sent to 0788123456', amount: 1500, direction: Direction.outgoing),
    const Transaction(id: 3, description: 'Cash out', amount: 800, direction: Direction.outgoing),
    const Transaction(id: 4, description: 'Received from Jean', amount: 2500, direction: Direction.incoming),
    const Transaction(id: 5, description: 'Sent to 0791234567', amount: 200, direction: Direction.outgoing),
  ];

  int _nextId = 6;
  Transaction? _lastDeleted;
  int _lastDeletedPosition = 0;

  List<Transaction> get newestFirst => _history.reversed.toList();

  int get balance => _balanceOf(_history);

  int get totalIn => _history
      .where((t) => t.direction == Direction.incoming)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalOut => _history
      .where((t) => t.direction == Direction.outgoing)
      .fold(0, (sum, t) => sum + t.amount);

  int get lowestBalance => _lowestOf(_history);

  void _add(String description, int amount, Direction direction) {
    _history.add(Transaction(
      id: _nextId++,
      description: description,
      amount: amount,
      direction: direction,
    ));
  }

  String? addIncoming(int amount, String description) {
    if (description.trim().isEmpty) return 'Description cannot be empty';
    if (amount <= 0) return 'Amount must be a whole number above 0';
    _add(description.trim(), amount, Direction.incoming);
    return null;
  }

  String? send(String phone, int amount) {
    final phoneError = checkPhone(phone);
    if (phoneError != null) return phoneError;
    if (amount < 100) return 'Send at least 100 RWF';
    if (amount > balance) return 'Insufficient balance';
    _add('Sent to ${phone.trim()}', amount, Direction.outgoing);
    return null;
  }

  String? cashOut(int amount) {
    if (splitIntoNotes(amount) == null) {
      return 'Amount must be a multiple of 100 (for example 500 or 1000)';
    }
    if (amount > balance) return 'Insufficient balance';
    _add('Cash out', amount, Direction.outgoing);
    return null;
  }

  String? delete(int id) {
    final position = _history.indexWhere((t) => t.id == id);
    if (position == -1) return 'Transaction not found';

    final withoutIt = [..._history]..removeAt(position);
    if (_lowestOf(withoutIt) < 0) {
      return 'Cannot delete: the balance would go below 0';
    }

    _lastDeleted = _history.removeAt(position);
    _lastDeletedPosition = position;
    return null;
  }

  void undoDelete() {
    final t = _lastDeleted;
    if (t == null) return;
    _history.insert(_lastDeletedPosition, t);
    _lastDeleted = null;
  }
}