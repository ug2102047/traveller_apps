import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/local_bookings.dart';
import '../models/booking.dart';

const String _kAdminPrefKey = 'is_admin_logged_in';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  // (OLD helper removed — replaced by _handleAdminAction which handles payment-related updates)

  Future<void> _sendNotification(
    String userId,
    String? email,
    String subject,
    String message,
  ) async {
    // Write a notification document. You can hook a Cloud Function or the Firebase "trigger-email" extension
    // to send an email when a document is added to this collection.
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'email': email ?? '',
      'subject': subject,
      'message': message,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleAdminAction(
    QueryDocumentSnapshot doc,
    String action,
    String adminId,
  ) async {
    final id = doc.id;
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final userId = d['userId'] as String? ?? '';
    final userEmail = d['email'] as String? ?? '';
    final paidAmount = (d['paidAmount'] is num)
        ? (d['paidAmount'] as num).toDouble()
        : (double.tryParse('${d['paidAmount']}') ?? 0.0);
    // totalAmount not required here, compute if needed later
    if (action == 'confirm') {
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({
        'status': 'confirmed',
        'adminId': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _sendNotification(
        userId,
        userEmail,
        'Booking Confirmed',
        'Your booking has been confirmed by admin.',
      );
    } else if (action == 'cancel') {
      // mark cancelled and if any amount paid, mark refund due
      final updates = {
        'status': 'cancelled',
        'adminId': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (paidAmount > 0) {
        updates['paymentStatus'] = 'refund_due';
        updates['refundAmount'] = paidAmount;
      }
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update(updates);
      await _sendNotification(
        userId,
        userEmail,
        'Booking Cancelled',
        'Your booking has been cancelled by admin. Refund will be processed if payment was made.',
      );
    }
  }

  Future<bool> _isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAdminPrefKey) == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapAdmin) {
        if (!snapAdmin.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isAdmin = snapAdmin.data == true;
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin: Bookings')),
            body: const Center(
              child: Text('Admin access required. Please sign in as admin.'),
            ),
          );
        }

        final user = FirebaseAuth.instance.currentUser;
        final adminId = user?.uid ?? 'local-admin';

        final stream = FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('created_at', descending: true)
            .snapshots();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin: Bookings'),
            actions: [
              IconButton(
                tooltip: 'Sign out admin',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_kAdminPrefKey);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
            ],
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: getLocalBookings(),
            builder: (context, localSnap) {
              final localList = localSnap.data ?? [];
              return StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty && localList.isEmpty) {
                    return const Center(child: Text('No bookings'));
                  }

                  final children = <Widget>[];
                  for (final doc in docs) {
                    final b = Booking.fromDoc(doc);
                    children.add(
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(b.hotelName),
                          subtitle: Text('Guest: ${b.name} • ${b.status}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              await _handleAdminAction(doc, v, adminId);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'confirm',
                                child: Text('Confirm'),
                              ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(b.hotelName),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Name: ${b.name}'),
                                      Text('Phone: ${b.phone}'),
                                      Text('Email: ${b.email}'),
                                      Text(
                                        'Dates: ${b.checkIn.toLocal().toString().split(' ')[0]} - ${b.checkOut.toLocal().toString().split(' ')[0]}',
                                      ),
                                      Text('Rooms: ${b.rooms}'),
                                      Text('Status: ${b.status}'),
                                      // show payment fields if present in document
                                      Builder(
                                        builder: (_) {
                                          final map =
                                              doc.data()
                                                  as Map<String, dynamic>? ??
                                              {};
                                          final paid = map['paidAmount'];
                                          final pStatus = map['paymentStatus'];
                                          final total = map['totalAmount'];
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (total != null)
                                                Text(
                                                  'Total: BDT ${total.toString()}',
                                                ),
                                              if (paid != null)
                                                Text(
                                                  'Paid: BDT ${paid.toString()}',
                                                ),
                                              if (pStatus != null)
                                                Text(
                                                  'Payment status: ${pStatus.toString()}',
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      if (b.adminNote != null)
                                        Text('Admin note: ${b.adminNote}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // confirm
                                      Navigator.of(ctx).pop();
                                      await _handleAdminAction(
                                        doc,
                                        'confirm',
                                        adminId,
                                      );
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      await _handleAdminAction(
                                        doc,
                                        'cancel',
                                        adminId,
                                      );
                                    },
                                    child: const Text('Cancel booking'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  // Add local unsynced bookings below remote ones
                  for (final m in localList) {
                    final localId = m['localId'] as String?;
                    children.add(
                      Card(
                        color: Colors.yellow[50],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(m['hotelName'] ?? 'Local Booking'),
                          subtitle: Text(
                            'Guest: ${m['name'] ?? ''} • ${m['status'] ?? 'pending'} (local)',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (localId == null) return;
                              if (v == 'confirm') {
                                await updateLocalBooking(localId, {
                                  'status': 'confirmed',
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Local booking marked confirmed',
                                    ),
                                  ),
                                );
                              } else if (v == 'cancel') {
                                await updateLocalBooking(localId, {
                                  'status': 'cancelled',
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Local booking marked cancelled',
                                    ),
                                  ),
                                );
                              } else if (v == 'refund') {
                                // mark refund processed locally
                                await updateLocalBooking(localId, {
                                  'paymentStatus': 'refunded',
                                  'refundProcessed': true,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Local booking marked refunded',
                                    ),
                                  ),
                                );
                              }
                              // rebuild UI by calling setState via navigator pop & push (quick hack)
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/admin-bookings');
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'confirm',
                                child: Text('Confirm'),
                              ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel'),
                              ),
                              const PopupMenuItem(
                                value: 'refund',
                                child: Text('Mark refunded'),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(m['hotelName'] ?? 'Local Booking'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Name: ${m['name'] ?? ''}'),
                                      Text('Phone: ${m['phone'] ?? ''}'),
                                      Text('Email: ${m['email'] ?? ''}'),
                                      Text('Rooms: ${m['rooms'] ?? ''}'),
                                      Text(
                                        'Status: ${m['status'] ?? ''} (local)',
                                      ),
                                      if (m['paidAmount'] != null)
                                        Text('Paid: BDT ${m['paidAmount']}'),
                                      if (m['totalAmount'] != null)
                                        Text('Total: BDT ${m['totalAmount']}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      if (localId != null) {
                                        await updateLocalBooking(localId, {
                                          'status': 'confirmed',
                                        });
                                        if (context.mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Local booking marked confirmed',
                                              ),
                                            ),
                                          );
                                        if (context.mounted)
                                          Navigator.of(
                                            context,
                                          ).pushReplacementNamed(
                                            '/admin-bookings',
                                          );
                                      }
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      if (localId != null) {
                                        await updateLocalBooking(localId, {
                                          'status': 'cancelled',
                                        });
                                        if (context.mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Local booking marked cancelled',
                                              ),
                                            ),
                                          );
                                        if (context.mounted)
                                          Navigator.of(
                                            context,
                                          ).pushReplacementNamed(
                                            '/admin-bookings',
                                          );
                                      }
                                    },
                                    child: const Text('Cancel booking'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: children,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
