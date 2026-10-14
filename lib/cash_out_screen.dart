import 'package:flutter/material.dart';
import 'wallet.dart';
import 'wallet_screen.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final amountController = TextEditingController();
  String? error;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = parseWholeNumber(amountController.text);
    if (amount == null) {
      setState(() {
        error = 'Amount must be a whole number above 0';
      });
      return;
    }

    final result = widget.wallet.cashOut(amount);
    if (result != null) {
      setState(() {
        error = result;
      });
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final amount = parseWholeNumber(amountController.text);
    final notes = amount == null ? null : splitIntoNotes(amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash out')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                setState(() {
                  error = null;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (notes != null)
              Text(
                'The agent will give you: '
                    '${notes.entries.map((e) => '${formatRwf(e.key)} × ${e.value}').join(' · ')}',
              ),
            if (amount != null && notes == null)
              const Text(
                'Amount must be a multiple of 100',
                style: TextStyle(color: Colors.orange),
              ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}