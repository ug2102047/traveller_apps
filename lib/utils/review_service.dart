import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for submitting reviews and maintaining per-target rating aggregates.
class ReviewService {
  /// Submit a review for a target (place/hotel/etc).
  ///
  /// Writes a new document into `reviews` and updates the aggregate in
  /// `ratings/<target>` inside a Firestore transaction.
  static Future<void> submitReview({
    required String targetType,
    required String target,
    required int rating,
    required String comment,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      // Prefer email (user requested) then displayName, otherwise fall back
      // to uid so the UI never shows a null/empty value.
      final savedUserName = ((user?.email ?? '').trim().isNotEmpty)
          ? (user!.email!)
          : (((user?.displayName ?? '').trim().isNotEmpty)
                ? user!.displayName!
                : uid);

      // Only write the review document. Ratings aggregates are updated
      // server-side (Cloud Function) to avoid client-side tampering and
      // to match restrictive Firestore security rules.
      await firestore.collection('reviews').add({
        'targetType': targetType,
        'target': target,
        'rating': rating,
        'comment': comment,
        'userId': uid,
        'user': savedUserName,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      // Unwrap common exception shapes into a readable message so the UI
      // receives a concise error instead of a boxed/converted Future value.
      String msg = 'Failed to submit review.';
      try {
        final dynamic de = e;
        if (de is FirebaseException) {
          msg = de.message ?? de.toString();
        } else if (de != null) {
          try {
            if (de is Map && de['error'] != null) {
              msg = de['error'].toString();
            } else if (de is Object && (de as dynamic).message != null) {
              msg = (de as dynamic).message.toString();
            } else {
              msg = de.toString();
            }
          } catch (_) {
            msg = de.toString();
          }
        }
      } catch (_) {
        msg = e.toString();
      }

      // Debug logs (ignore: avoid_print lint in production)
      // ignore: avoid_print
      print('ReviewService.submitReview error: $e');
      // ignore: avoid_print
      print(st);

      throw Exception('Review submission failed: $msg');
    }
  }
}
