import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cash_out_screen.dart';
import 'send_screen.dart';
import 'transaction.dart';
import 'wallet.dart';

enum Filter { all, incoming, outgoing }

// Shows the transactions that match the chosen filter, newest first.
List<Transaction> filterTransactions(List<Transaction> items, Filter filter) {
  switch (filter) {
    case Filter.all:
      return items;
    case Filter.incoming:
      return items.where((t) => t.direction == Direction.incoming).toList();
    case Filter.outgoing:
      return items.where((t) => t.direction == Direction.outgoing).toList();
  }
}

// Turns 13000 into "13,000".
String formatRwf(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Filter filter = Filter.all;

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('MoMo Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      );

  Widget _plain(Widget body) => Scaffold(appBar: _appBar(), body: body);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: myTransactions().orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _plain(Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your transactions.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ));
        }
        if (!snapshot.hasData) {
          return _plain(const Center(child: CircularProgressIndicator()));
        }

        // The stream gives newest first; Wallet wants oldest first.
        final txns = snapshot.data!.docs.map(Transaction.fromDoc).toList();
        final wallet = Wallet(txns.reversed.toList());
        final shown = filterTransactions(wallet.newestFirst, filter);

        return Scaffold(
          appBar: _appBar(),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'send',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendScreen(wallet: wallet),
                  ),
                ),
                label: const Text('Send money'),
                icon: const Icon(Icons.send),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'cashout',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashOutScreen(wallet: wallet),
                  ),
                ),
                label: const Text('Cash out'),
                icon: const Icon(Icons.local_atm),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance', style: TextStyle(color: Colors.white)),
                      Text(
                        'RWF ${formatRwf(wallet.balance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(label: 'Total in', value: formatRwf(wallet.totalIn)),
                    ),
                    Expanded(
                      child: _StatBox(label: 'Total out', value: formatRwf(wallet.totalOut)),
                    ),
                    Expanded(
                      child: _StatBox(label: 'Lowest', value: formatRwf(wallet.lowestBalance)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _filterChip('All', Filter.all),
                    const SizedBox(width: 8),
                    _filterChip('IN', Filter.incoming),
                    const SizedBox(width: 8),
                    _filterChip('OUT', Filter.outgoing),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: shown.isEmpty
                      ? const Center(child: Text('No transactions to show'))
                      : ListView.builder(
                          itemCount: shown.length,
                          itemBuilder: (context, index) {
                            final t = shown[index];
                            final isIn = t.direction == Direction.incoming;
                            return ListTile(
                              title: Text(t.description),
                              subtitle: Text(isIn ? 'IN' : 'OUT'),
                              onLongPress: () => _delete(context, wallet, t),
                              trailing: Text(
                                '${isIn ? '+' : '-'} ${formatRwf(t.amount)}',
                                style: TextStyle(
                                  color: isIn ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, Wallet wallet, Transaction t) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: Text(t.description),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;

    final error = await wallet.delete(t.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Transaction deleted'),
        action: error == null
            ? SnackBarAction(label: 'Undo', onPressed: wallet.undoDelete)
            : null,
      ),
    );
  }

  Widget _filterChip(String label, Filter value) {
    return ChoiceChip(
      label: Text(label),
      selected: filter == value,
      onSelected: (_) => setState(() => filter = value),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
