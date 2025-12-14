import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'contact_thread_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/contact_service.dart';

class MyConversationsScreen extends StatefulWidget {
  const MyConversationsScreen({super.key});

  @override
  State<MyConversationsScreen> createState() => _MyConversationsScreenState();
}

class _MyConversationsScreenState extends State<MyConversationsScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loadingPending = true;
  List<QueryDocumentSnapshot> _emailThreads = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
    // Attempt to claim and also load threads that may be tied to the user's email
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ContactService.claimServerThreadsForCurrentUser();
      } catch (_) {}
      await _loadEmailThreads();
    });
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pending_contacts') ?? [];
    _pending = list.map((s) => json.decode(s) as Map<String, dynamic>).toList();
    if (mounted) setState(() => _loadingPending = false);
  }

  Future<void> _syncNow() async {
    setState(() => _loadingPending = true);
    final res = await ContactService.syncPendingMessages();
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${res['success']} pending, ${res['failed']} failed',
          ),
        ),
      );
    }
  }

  Future<void> _loadEmailThreads() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      final q = await FirebaseFirestore.instance
          .collection('contacts')
          .where('userEmail', isEqualTo: email)
          .orderBy('created_at', descending: true)
          .get();
      _emailThreads = q.docs;
      if (mounted) setState(() {});
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Conversations')),
        body: const Center(child: Text('Sign in to see your conversations')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('contacts')
        .where('userId', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Conversations'),
        actions: [
          if (_pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('Pending: ${_pending.length}')),
            ),
          IconButton(
            tooltip: 'Sync pending',
            icon: const Icon(Icons.sync),
            onPressed: _loadingPending ? null : _syncNow,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingPending)
            const LinearProgressIndicator()
          else if (_pending.isNotEmpty)
            Container(
              color: Colors.yellow[50],
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending (local) messages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._pending.map(
                    (p) => ListTile(
                      title: Text((p['subject'] ?? '').toString()),
                      subtitle: Text(
                        (p['message'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snap.hasError) {
                  return Center(
                    child: Text('Error loading conversations: ${snap.error}'),
                  );
                }
                final docs = snap.data?.docs ?? [];
                // Merge in any email-matching threads that may not yet have userId set
                final Map<String, QueryDocumentSnapshot> combined = {
                  for (final d in docs) d.id: d,
                };
                for (final d in _emailThreads) {
                  if (!combined.containsKey(d.id)) combined[d.id] = d;
                }
                final mergedList = combined.values.toList()
                  ..sort((a, b) {
                    final aMap = a.data() as Map<String, dynamic>?;
                    final bMap = b.data() as Map<String, dynamic>?;
                    final aTs = aMap == null ? null : aMap['created_at'];
                    final bTs = bMap == null ? null : bMap['created_at'];
                    if (aTs is Timestamp && bTs is Timestamp) {
                      return bTs.compareTo(aTs);
                    }
                    return 0;
                  });
                if (mergedList.isEmpty)
                  return const Center(child: Text('No conversations yet'));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: mergedList.length,
                  itemBuilder: (c, i) {
                    final d = mergedList[i];
                    final m = d.data() as Map<String, dynamic>;
                    final subject = (m['subject'] ?? '').toString();
                    final last = (m['lastMessage'] ?? '').toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ContactThreadScreen(contactId: d.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
