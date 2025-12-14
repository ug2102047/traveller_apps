import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/local_bookings.dart';
import 'mock_wallet_payment_screen.dart';

enum _PaymentMethod { bkash, nagad }

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _roomsController = TextEditingController(text: '1');
  final _amountController = TextEditingController(
    text: '1000',
  ); // default total

  _PaymentMethod _paymentMethod = _PaymentMethod.bkash;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _roomsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final checkIn = _checkInController.text.trim();
    final checkOut = _checkOutController.text.trim();
    final rooms = int.tryParse(_roomsController.text) ?? 1;
    final total = double.tryParse(_amountController.text) ?? 0.0;

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name and phone required')));
      return;
    }

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;

    // Decide payment flow based on chosen payment method
    double amountToPay = 0.0;

    // For this app, require 20% advance via wallet (bKash/Nagad) before booking.
    amountToPay = (total * 0.20);

    // Open mock wallet/payment screen to simulate bKash/Nagad payment
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MockWalletPaymentScreen(amount: amountToPay),
      ),
    );

    // If payment failed (user cancelled), stop
    if (paid != true) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Save booking to Firestore (or local fallback on error)
    final bookingData = {
      'userId': user?.uid ?? '',
      'hotelId': '',
      'hotelName': 'Sample Hotel',
      'name': name,
      'phone': phone,
      'email': email,
      'checkIn': DateTime.now(),
      'checkOut': DateTime.now().add(const Duration(days: 1)),
      'checkInInput': checkIn,
      'checkOutInput': checkOut,
      'rooms': rooms,
      'status': 'confirmed',
      'paymentMethod': _paymentMethod == _PaymentMethod.bkash
          ? 'bKash'
          : 'Nagad',
      'paymentStatus': 'partial',
      'paidAmount': amountToPay,
      'totalAmount': total,
      'created_at': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking successful')));
      Navigator.of(context).pop();
    } catch (e) {
      // Save locally when server write fails
      await saveLocalBooking(bookingData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offline Saved\nBooking could not be saved to server and was saved locally.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Hotel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Form',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _checkInController,
                decoration: const InputDecoration(labelText: 'Check-in Date'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _checkOutController,
                decoration: const InputDecoration(labelText: 'Check-out Date'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roomsController,
                decoration: const InputDecoration(labelText: 'Rooms'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total amount (BDT)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              const Text(
                'Payment method (required):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<_PaymentMethod>(
                title: const Text('bKash (20% advance)'),
                value: _PaymentMethod.bkash,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              RadioListTile<_PaymentMethod>(
                title: const Text('Nagad (20% advance)'),
                value: _PaymentMethod.nagad,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 8),
              Text(
                'Advance required now: BDT ${(double.tryParse(_amountController.text) ?? 0.0 * 0.20).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitBooking,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Confirm & Pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
