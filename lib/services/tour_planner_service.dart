// Tour Planner service removed.
// The UI files referencing this service have been removed or replaced.
// This stub preserves the symbol so any lingering imports do not break
// the build; it throws to indicate the feature is not available.

class TourPlannerService {
  static Future<dynamic> generatePlan({
    required String destination,
    required int days,
    required int people,
    required int budget,
    Map<String, dynamic>? preferences,
  }) async {
    throw StateError(
      'Tour Planner feature has been removed from this project.',
    );
  }
}
