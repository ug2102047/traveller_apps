import 'package:flutter/material.dart';

class MockWalletPaymentScreen extends StatelessWidget {
  final double amount;

  const MockWalletPaymentScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Wallet Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount to pay: BDT ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'This simulates a bKash/Nagad payment flow for demo purposes.',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Simulate processing delay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted)
                  Navigator.of(context).pop(); // remove progress
                // Return success
                Navigator.of(context).pop(true);
              },
              child: const Text('Simulate successful payment'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel / Back'),
            ),
          ],
        ),
      ),
    );
  }
}
