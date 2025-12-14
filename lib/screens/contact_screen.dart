import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_thread_screen.dart';
import '../services/contact_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    // Attempt to sync pending messages automatically when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPendingMessages());
  }

  Future<void> _loadPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pending_contacts') ?? [];
    if (mounted) setState(() => _pendingCount = list.length);
  }

  Future<void> _sendMessage() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subject and message')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Create a thread doc first
      final contactsColl = FirebaseFirestore.instance.collection('contacts');
      final docRef = contactsColl.doc();
      await docRef.set({
        'userId': user?.uid,
        'userEmail': user?.email ?? '',
        'subject': subject,
        'status': 'open',
        'created_at': Timestamp.now(),
        'lastMessage': message,
        'lastUpdated': Timestamp.now(),
      });

      // Add the first message in a subcollection `messages`
      await docRef.collection('messages').add({
        'senderId': user?.uid,
        'senderRole': 'user',
        'text': message,
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent — admin will reply soon')),
      );
      // Open the conversation screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ContactThreadScreen(contactId: docRef.id),
        ),
      );
    } on FirebaseException catch (fe) {
      // Handle permission denied specifically and provide a local fallback
      if (fe.code == 'permission-denied') {
        // Save to SharedPreferences as a pending contact so the user doesn't lose their message
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('pending_contacts') ?? [];
        final pending = json.encode({
          'subject': subject,
          'message': message,
          'userEmail': FirebaseAuth.instance.currentUser?.email ?? '',
          'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'created_at': DateTime.now().toIso8601String(),
        });
        list.insert(0, pending);
        await prefs.setStringList('pending_contacts', list);
        if (!mounted) return;
        _subjectCtrl.clear();
        _messageCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved locally — permission denied. Admin will not see it until rules allow writes.',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${fe.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
      await _loadPendingCount();
    }
  }

  Future<void> _syncPendingMessages() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing pending messages...')),
    );
    final res = await ContactService.syncPendingMessages();
    if (!mounted) return;
    await _loadPendingCount();
    final success = res['success'] ?? 0;
    final failed = res['failed'] ?? 0;
    final msg = success > 0
        ? 'Synced $success pending message(s).' +
              (failed > 0 ? ' $failed failed.' : '')
        : (failed > 0
              ? 'No pending messages were synced.'
              : 'No pending messages.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Admin'),
        actions: [
          IconButton(
            tooltip: 'My Conversations',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () =>
                Navigator.of(context).pushNamed('/my-conversations'),
          ),
          if (_pendingCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('Pending: $_pendingCount'),
              ),
            ),
          IconButton(
            tooltip: 'Sync pending',
            icon: const Icon(Icons.sync),
            onPressed: _syncPendingMessages,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendMessage,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
