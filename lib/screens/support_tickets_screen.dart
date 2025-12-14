import 'package:flutter/material.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, // Placeholder for number of tickets
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.support_agent,
                size: 40,
                color: Colors.orange[700],
              ),
              title: Text('Ticket #${index + 1}'),
              subtitle: const Text('Ticket details here'),
              onTap: () {
                // TODO: Navigate to ticket details
              },
            ),
          );
        },
      ),
    );
  }
}
