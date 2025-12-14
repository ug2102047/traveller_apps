import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../utils/local_bookings.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please sign in to view bookings')),
      );
    }
    final q = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: q,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final remoteDocs = snap.data?.docs ?? [];
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: getLocalBookings(),
            builder: (context, localSnap) {
              final localList =
                  localSnap.data
                      ?.where((m) => m['userId'] == user.uid)
                      .toList() ??
                  [];
              if ((remoteDocs.isEmpty) && localList.isEmpty) {
                return const Center(child: Text('No bookings found'));
              }

              // Build combined list: remote bookings first, then local unsynced
              final items = <Widget>[];

              for (final doc in remoteDocs) {
                final b = Booking.fromDoc(doc);
                items.add(_buildBookingTile(context, b, synced: true));
              }

              for (final m in localList) {
                items.add(_buildLocalBookingTile(context, m));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: items,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingTile(
    BuildContext context,
    Booking b, {
    bool synced = true,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.hotel, size: 40, color: Colors.green[700]),
        title: Text(b.hotelName.isNotEmpty ? b.hotelName : 'Hotel'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest: ${b.name}'),
            Text(
              'Dates: ${b.checkIn.toLocal().toString().split(' ')[0]} - ${b.checkOut.toLocal().toString().split(' ')[0]}',
            ),
            Text('Status: ${b.status}'),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showBookingDialog(
          context,
          b.hotelName,
          b.name,
          b.phone,
          b.email,
          b.rooms,
          b.status,
          b.adminNote,
        ),
      ),
    );
  }

  Widget _buildLocalBookingTile(BuildContext context, Map<String, dynamic> m) {
    return Card(
      color: Colors.yellow[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.hotel, size: 40, color: Colors.orange[700]),
        title: Text(m['hotelName'] ?? 'Local Booking'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest: ${m['name'] ?? ''}'),
            Text(
              'Dates: ${m['checkIn']?.toString().split('T')[0]} - ${m['checkOut']?.toString().split('T')[0]}',
            ),
            Text('Status: ${m['status'] ?? 'pending'} (local)'),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(m['hotelName'] ?? 'Local Booking'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${m['name'] ?? ''}'),
                    Text('Phone: ${m['phone'] ?? ''}'),
                    Text('Email: ${m['email'] ?? ''}'),
                    Text('Rooms: ${m['rooms'] ?? ''}'),
                    Text('Status: ${m['status'] ?? ''} (local)'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBookingDialog(
    BuildContext context,
    String title,
    String name,
    String phone,
    String email,
    int rooms,
    String status,
    String? adminNote,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Booking: $title'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: $name'),
              Text('Phone: $phone'),
              Text('Email: $email'),
              Text('Rooms: $rooms'),
              Text('Status: $status'),
              if (adminNote != null) Text('Admin note: $adminNote'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
