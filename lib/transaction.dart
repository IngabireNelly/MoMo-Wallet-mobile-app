import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

enum Direction { incoming, outgoing }

class Transaction {
  const Transaction({
    this.id = '',
    required this.description,
    required this.amount,
    required this.direction,
    this.createdAt,
  });

  final String id;
  final String description;
  final int amount;
  final Direction direction;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'isIn': direction == Direction.incoming,
      };

  factory Transaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Transaction(
      id: doc.id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toInt(),
      direction: (data['isIn'] as bool) ? Direction.incoming : Direction.outgoing,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// The signed-in user's transactions: users/{uid}/transactions
CollectionReference<Map<String, dynamic>> myTransactions() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions');
}

// Sample data, written once when a new account is created (oldest first).
Future<void> addSampleTransactions() async {
  const samples = [
    Transaction(description: 'Received from Aline', amount: 3000, direction: Direction.incoming),
    Transaction(description: 'Sent to 0788123456', amount: 1500, direction: Direction.outgoing),
    Transaction(description: 'Cash out', amount: 800, direction: Direction.outgoing),
    Transaction(description: 'Received from Jean', amount: 2500, direction: Direction.incoming),
    Transaction(description: 'Sent to 0791234567', amount: 200, direction: Direction.outgoing),
  ];
  final now = DateTime.now();
  final batch = FirebaseFirestore.instance.batch();
  for (var i = 0; i < samples.length; i++) {
    // Different times, so the order is the same as before.
    final time = now.subtract(Duration(minutes: samples.length - i));
    batch.set(myTransactions().doc(), {
      ...samples[i].toMap(),
      'createdAt': Timestamp.fromDate(time),
    });
  }
  await batch.commit();
}
