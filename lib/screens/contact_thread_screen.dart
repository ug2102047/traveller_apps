import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactThreadScreen extends StatefulWidget {
  final String contactId;
  const ContactThreadScreen({super.key, required this.contactId});

  @override
  State<ContactThreadScreen> createState() => _ContactThreadScreenState();
}

class _ContactThreadScreenState extends State<ContactThreadScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminFlag();
  }

  Future<void> _loadAdminFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('is_admin_logged_in') == true;
    if (mounted) setState(() => _isAdmin = flag);
  }

  Future<void> _sendReply() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final role = _isAdmin ? 'admin' : 'user';
      final docRef = FirebaseFirestore.instance
          .collection('contacts')
          .doc(widget.contactId);
      await docRef.collection('messages').add({
        'senderId': uid,
        'senderRole': role,
        'text': text,
        'created_at': Timestamp.now(),
      });
      // update thread summary
      await docRef.update({
        'lastMessage': text,
        'lastUpdated': Timestamp.now(),
        'status': _isAdmin ? 'replied' : 'open',
      });
      _ctrl.clear();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgsRef = FirebaseFirestore.instance
        .collection('contacts')
        .doc(widget.contactId)
        .collection('messages')
        .orderBy('created_at', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgsRef.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snap.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snap.error}'),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Center(child: Text('No messages'));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i];
                    final m = d.data() as Map<String, dynamic>;
                    final senderRole = (m['senderRole'] ?? 'user').toString();
                    final text = (m['text'] ?? '').toString();
                    final isMe =
                        (m['senderId'] ?? '') ==
                        FirebaseAuth.instance.currentUser?.uid;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderRole.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : _sendReply,
                  child: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
