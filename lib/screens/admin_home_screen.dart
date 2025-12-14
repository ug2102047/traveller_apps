import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAdminPrefKey = 'is_admin_logged_in';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _signOutAdmin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAdminPrefKey);
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out admin',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOutAdmin(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.book_online),
              label: const Text('Manage Bookings'),
              onPressed: () => Navigator.pushNamed(context, '/admin-bookings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.contact_mail),
              label: const Text('Manage Contacts'),
              onPressed: () => Navigator.pushNamed(context, '/admin-contacts'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
