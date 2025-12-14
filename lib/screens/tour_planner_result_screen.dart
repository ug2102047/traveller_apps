import 'package:flutter/material.dart';

/// Placeholder result screen for the removed Tour Planner feature.
class TourPlannerResultScreen extends StatelessWidget {
  const TourPlannerResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tour Planner')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tour Planner results are not available. The feature was removed.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
