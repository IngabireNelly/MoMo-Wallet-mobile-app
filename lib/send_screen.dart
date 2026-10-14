import 'package:flutter/material.dart';
import 'wallet.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  String? error;

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _send() {
    final amount = parseWholeNumber(amountController.text);
    if (amount == null) {
      setState(() {
        error = 'Amount must be a whole number above 0';
      });
      return;
    }

    final result = widget.wallet.send(phoneController.text, amount);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _send,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}