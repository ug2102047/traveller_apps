import 'package:flutter/material.dart';

/// Tour Planner UI removed
/// This screen remains as a harmless placeholder for any lingering routes/imports.
class TourPlannerScreen extends StatelessWidget {
  const TourPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tour Planner')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'The Tour Planner feature has been removed from this app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
