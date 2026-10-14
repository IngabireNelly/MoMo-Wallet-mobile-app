enum Direction { incoming, outgoing }

class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.direction,
  });

  final int id;
  final String description;
  final int amount;
  final Direction direction;
}