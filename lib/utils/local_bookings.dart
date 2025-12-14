import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kLocalBookingsKey = 'local_bookings_v1';

Future<List<Map<String, dynamic>>> getLocalBookings() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kLocalBookingsKey) ?? [];
  return list
      .map((s) => Map<String, dynamic>.from(json.decode(s) as Map))
      .toList();
}

Future<void> saveLocalBooking(Map<String, dynamic> booking) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kLocalBookingsKey) ?? [];
  list.insert(0, json.encode(booking));
  await prefs.setStringList(_kLocalBookingsKey, list);
}

Future<void> removeLocalBooking(String localId) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kLocalBookingsKey) ?? [];
  final filtered = list.where((s) {
    try {
      final m = json.decode(s) as Map<String, dynamic>;
      return (m['localId'] as String?) != localId;
    } catch (_) {
      return true;
    }
  }).toList();
  await prefs.setStringList(_kLocalBookingsKey, filtered);
}

Future<void> updateLocalBooking(
  String localId,
  Map<String, dynamic> updates,
) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kLocalBookingsKey) ?? [];
  final newList = <String>[];
  for (final s in list) {
    try {
      final m = Map<String, dynamic>.from(json.decode(s) as Map);
      if ((m['localId'] as String?) == localId) {
        m.addAll(updates);
        newList.add(json.encode(m));
      } else {
        newList.add(s);
      }
    } catch (_) {
      newList.add(s);
    }
  }
  await prefs.setStringList(_kLocalBookingsKey, newList);
}

/// Try to push locally-saved bookings to Firestore.
/// On success the local entry is removed. Failures are left for retry.
Future<void> syncLocalBookings() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kLocalBookingsKey) ?? [];
  if (list.isEmpty) return;

  final newList = List<String>.from(list);
  for (final s in List<String>.from(list)) {
    try {
      final m = Map<String, dynamic>.from(json.decode(s) as Map);
      // Skip if already flagged synced
      if ((m['synced'] as bool?) == true) {
        newList.remove(s);
        continue;
      }

      // Ensure we have an authenticated user; try anonymous sign-in if none
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (_) {
        // ignore sign-in failures; we'll skip upload if no auth
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Prepare payload for Firestore: convert ISO dates if necessary
      final payload = Map<String, dynamic>.from(m);
      payload.remove('localId');
      payload['created_at'] = FieldValue.serverTimestamp();

      // Ensure userId matches authenticated uid (or set if missing)
      if (uid != null) {
        payload['userId'] = uid;
      }

      // convert checkIn/checkOut strings to Timestamps if present
      try {
        if (payload['checkIn'] is String) {
          payload['checkIn'] = Timestamp.fromDate(
            DateTime.parse(payload['checkIn']),
          );
        }
        if (payload['checkOut'] is String) {
          payload['checkOut'] = Timestamp.fromDate(
            DateTime.parse(payload['checkOut']),
          );
        }
      } catch (_) {}

      // Coerce numeric fields to numbers
      try {
        if (payload['paidAmount'] != null) {
          payload['paidAmount'] =
              double.tryParse(payload['paidAmount'].toString()) ?? 0.0;
        }
        if (payload['totalAmount'] != null) {
          payload['totalAmount'] =
              double.tryParse(payload['totalAmount'].toString()) ?? 0.0;
        }
      } catch (_) {}

      // Ensure paymentStatus is valid
      final ps = (payload['paymentStatus'] as String?) ?? 'partial';
      if (!(ps == 'pending' ||
          ps == 'partial' ||
          ps == 'paid' ||
          ps == 'refunded')) {
        payload['paymentStatus'] = 'partial';
      }

      // If we still don't have an authenticated uid, skip upload for now
      if (FirebaseAuth.instance.currentUser == null) {
        continue;
      }

      // Attempt to write to Firestore
      await FirebaseFirestore.instance.collection('bookings').add(payload);

      // On success remove the local entry
      newList.remove(s);
    } catch (_) {
      // ignore and leave entry in local list for future retry
      continue;
    }
  }

  await prefs.setStringList(_kLocalBookingsKey, newList);
}
