import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_thread_screen.dart';

const String _kAdminPrefKey = 'is_admin_logged_in';
const String _kAdminEmailKey = 'admin_email';

class AdminContactsScreen extends StatefulWidget {
  const AdminContactsScreen({super.key});

  @override
  State<AdminContactsScreen> createState() => _AdminContactsScreenState();
}

class _AdminContactsScreenState extends State<AdminContactsScreen> {
  bool? _isAdmin;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminFlag();
  }

  Future<void> _loadAdminFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(_kAdminPrefKey) == true;
    final email = prefs.getString(_kAdminEmailKey);
    if (mounted) setState(() => _isAdmin = flag);
    _adminEmail = email;
  }

  Future<void> _signInAdmin() async {
    // Prompt for admin credentials and sign in with Firebase Auth.
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final result = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Sign In (dev)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAdminPrefKey, true);
      await prefs.setString(_kAdminEmailKey, email);

      if (mounted) {
        setState(() {
          _isAdmin = true;
          _adminEmail = email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in as admin (dev)')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin sign-in failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Admin sign-in failed: $e')));
    }
  }

  Future<void> _signOutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAdminPrefKey);
    await prefs.remove(_kAdminEmailKey);

    // If currently signed in as the stored admin email, sign out from FirebaseAuth.
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null &&
          _adminEmail != null &&
          current.email == _adminEmail) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isAdmin = false);
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ---------- ADMIN NOT LOGGED IN ----------
    if (!_isAdmin!) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin: Contacts')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Admin access required.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _signInAdmin,
                child: const Text('Sign in as Admin (dev)'),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Note: This only sets a local development flag.\n'
                  'For production, use proper admin accounts with Firebase custom claims.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ---------- ADMIN LOGGED IN ----------
    final stream = FirebaseFirestore.instance
        .collection('contacts')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Contacts'),
        actions: [
          IconButton(
            tooltip: 'Sign out admin',
            icon: const Icon(Icons.logout),
            onPressed: _signOutAdmin,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading contacts: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No contacts'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>;

              final subject = m['subject'] ?? '';
              final userEmail = m['userEmail'] ?? '';
              final lastMessage = m['lastMessage'] ?? '';
              final status = m['status'] ?? 'open';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ContactThreadScreen(contactId: d.id),
                      ),
                    );
                  },
                  title: Text(subject.toString()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lastMessage.toString()),
                      const SizedBox(height: 6),
                      Text(
                        'From: $userEmail • Status: $status',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'reply') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ContactThreadScreen(contactId: d.id),
                          ),
                        );
                      }

                      if (v == 'mark_open') {
                        await FirebaseFirestore.instance
                            .collection('contacts')
                            .doc(d.id)
                            .update({'status': 'open'});
                      }

                      if (v == 'delete') {
                        await FirebaseFirestore.instance
                            .collection('contacts')
                            .doc(d.id)
                            .delete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'reply',
                        child: Text('Open Thread'),
                      ),
                      const PopupMenuItem(
                        value: 'mark_open',
                        child: Text('Mark Open'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
