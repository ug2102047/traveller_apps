import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/review_service.dart';

class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({super.key});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  bool _loading = false;

  Widget _star(int index, void Function() onTap, int current) {
    final filled = index <= current;
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.star,
        color: filled ? Colors.amber : Colors.grey.shade300,
        size: 28,
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext ctx, String targetType) async {
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    int rating = 0;

    await showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (c, setState) {
          return AlertDialog(
            title: Text(
              'Add review for ${targetType == 'place' ? 'Place' : 'Hotel'}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Place / Hotel name',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => i + 1).map((i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: _star(i, () => setState(() => rating = i), rating),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write your review...',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final comment = commentController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name')),
                    );
                    return;
                  }
                  if (rating <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a rating')),
                    );
                    return;
                  }

                  setState(() => _loading = true);
                  try {
                    await ReviewService.submitReview(
                      targetType: targetType,
                      target: name,
                      rating: rating,
                      comment: comment,
                    );
                    Navigator.pop(dCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  } finally {
                    setState(() => _loading = false);
                  }
                },
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewList(String targetType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('targetType', isEqualTo: targetType)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Text('Error: ${snap.error}');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No reviews yet.');

        final docsList = List<QueryDocumentSnapshot>.from(docs);
        docsList.sort((a, b) {
          final aMap = a.data() as Map<String, dynamic>;
          final bMap = b.data() as Map<String, dynamic>;
          final aTs = aMap['created_at'];
          final bTs = bMap['created_at'];
          if (aTs is Timestamp && bTs is Timestamp) return bTs.compareTo(aTs);
          return 0;
        });

        return Column(
          children: docsList.map((d) {
            final r = d.data() as Map<String, dynamic>;
            final user = (r['user'] ?? r['userId'] ?? 'Anonymous').toString();
            final comment = (r['comment'] ?? '').toString();
            final rating = (r['rating'] ?? 0).toString();
            final target = (r['target'] ?? '').toString();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(user),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment),
                    if (target.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Name: $target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(rating),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reviews')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews for Places',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context, 'place'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Review'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildReviewList('place'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews for Hotels',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context, 'hotel'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Review'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildReviewList('hotel'),
          ],
        ),
      ),
    );
  }
}
