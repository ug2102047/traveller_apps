import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactService {
  /// Read pending contacts from SharedPreferences and attempt to push them
  /// to Firestore. Returns a map with counts: { 'success': n, 'failed': m }.
  static Future<Map<String, int>> syncPendingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pending_contacts') ?? [];
    if (list.isEmpty) return {'success': 0, 'failed': 0};

    int success = 0;
    final failed = <String>[];

    for (final item in List<String>.from(list)) {
      try {
        final m = json.decode(item) as Map<String, dynamic>;
        final contactsColl = FirebaseFirestore.instance.collection('contacts');
        final docRef = contactsColl.doc();
        // Use saved userId if present so the original owner remains the thread owner
        final originalUserId = (m['userId'] ?? '') as String?;
        final ownerId = (originalUserId != null && originalUserId.isNotEmpty)
            ? originalUserId
            : FirebaseAuth.instance.currentUser?.uid;
        await docRef.set({
          'userId': ownerId,
          'userEmail': m['userEmail'] ?? '',
          'subject': m['subject'] ?? '',
          'status': 'open',
          'created_at': Timestamp.now(),
          'lastMessage': m['message'] ?? '',
          'lastUpdated': Timestamp.now(),
        });
        await docRef.collection('messages').add({
          'senderId': ownerId,
          'senderRole': 'user',
          'text': m['message'] ?? '',
          'created_at': Timestamp.now(),
        });
        success++;
        // remove this item locally
        list.remove(item);
      } catch (e) {
        failed.add(item);
      }
    }

    await prefs.setStringList('pending_contacts', list);
    return {'success': success, 'failed': failed.length};
  }

  /// If a user signs in with a (non-anonymous) account, claim any existing
  /// server-side contact threads that were created with the same email but
  /// have a different `userId`. This helps users see conversations started
  /// earlier (for example while anonymous) after they log in.
  ///
  /// Returns the number of threads updated.
  static Future<int> claimServerThreadsForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email ?? '').isEmpty) return 0;

    final email = user.email!;
    final coll = FirebaseFirestore.instance.collection('contacts');
    final q = await coll.where('userEmail', isEqualTo: email).get();
    int updated = 0;
    for (final doc in q.docs) {
      final data = doc.data();
      final existingOwner = (data['userId'] ?? '').toString();
      if (existingOwner != user.uid) {
        try {
          await coll.doc(doc.id).update({'userId': user.uid});
          updated++;
        } catch (_) {
          // ignore failures (rules may prevent update) — continue
        }
      }
    }
    return updated;
  }
}
