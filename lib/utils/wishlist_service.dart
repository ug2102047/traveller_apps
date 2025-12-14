import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  static final _col = FirebaseFirestore.instance.collection('wishlists');

  static String? _uid() => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> addToWishlist({
    required String targetType,
    required String targetId,
    String? name,
    Map<String, dynamic>? extra,
  }) async {
    final uid = _uid();
    if (uid == null) throw Exception('Sign-in required to save wishlist items');

    final payload = {
      'userId': uid,
      'targetType': targetType,
      'targetId': targetId,
      'name': name ?? '',
      'extra': extra ?? {},
      'created_at': FieldValue.serverTimestamp(),
    };

    await _col.add(payload);
  }

  static Future<void> removeFromWishlist({
    required String targetType,
    required String targetId,
  }) async {
    final uid = _uid();
    if (uid == null) throw Exception('Sign-in required to modify wishlist');
    final q = await _col
        .where('userId', isEqualTo: uid)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .get();
    for (final d in q.docs) {
      await d.reference.delete();
    }
  }

  static Stream<QuerySnapshot> streamWishlistForType(String targetType) {
    final uid = _uid();
    if (uid == null) return const Stream.empty();
    return _col
        .where('userId', isEqualTo: uid)
        .where('targetType', isEqualTo: targetType)
        .snapshots();
  }

  static Future<bool> isWishlisted({
    required String targetType,
    required String targetId,
  }) async {
    final uid = _uid();
    if (uid == null) return false;
    final q = await _col
        .where('userId', isEqualTo: uid)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }
}
