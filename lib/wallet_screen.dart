import 'send_screen.dart';
import 'package:flutter/material.dart';
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
  final Wallet wallet = Wallet();
  Filter filter = Filter.all;

  @override
  Widget build(BuildContext context) {
    final shown = filterTransactions(wallet.newestFirst, filter);

    return Scaffold(
      appBar: AppBar(title: const Text('4MoMo Wallet')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SendScreen(wallet: wallet),
            ),
          ).then((_) {
            setState(() {});
          });
        },
        label: const Text('Send money'),
        icon: const Icon(Icons.send),
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
                  child: _StatBox(
                    label: 'Total in',
                    value: formatRwf(wallet.totalIn),
                  ),
                ),
                Expanded(
                  child: _StatBox(
                    label: 'Total out',
                    value: formatRwf(wallet.totalOut),
                  ),
                ),
                Expanded(
                  child: _StatBox(
                    label: 'Lowest',
                    value: formatRwf(wallet.lowestBalance),
                  ),
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
  }

  Widget _filterChip(String label, Filter value) {
    return ChoiceChip(
      label: Text(label),
      selected: filter == value,
      onSelected: (_) {
        setState(() {
          filter = value;
        });
      },
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