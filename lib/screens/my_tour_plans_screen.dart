import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Tour Planner feature removed; saved plans are not available.

class MyTourPlansScreen extends StatelessWidget {
  const MyTourPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tour Plans')),
        body: const Center(child: Text('Please sign in to view saved plans')),
      );
    }

    // Tour Planner feature removed — show informational placeholder.
    return Scaffold(
      appBar: AppBar(title: const Text('My Tour Plans')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('The Tour Planner feature has been removed.'),
        ),
      ),
    );
  }
}
