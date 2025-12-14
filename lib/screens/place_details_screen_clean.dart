import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/wishlist_service.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsScreen({required this.place, super.key});

  @override
  Widget build(BuildContext context) {
    final placeName = (place['name'] ?? '').toString();
    final placeId = (place['id'] ?? place['place_id'] ?? '').toString();
    final target = placeName.isNotEmpty ? placeName : placeId;

    return Scaffold(
      appBar: AppBar(
        title: Text(placeName.isNotEmpty ? placeName : 'Place Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((place['image'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: place['image'].toString().startsWith('http')
                    ? Image.network(
                        place['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        place['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            const SizedBox(height: 12),
            Text(
              placeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              place['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Reviews header with aggregate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ratings')
                      .doc(target)
                      .snapshots(),
                  builder: (ctx, s) {
                    if (!s.hasData || s.data == null) return const SizedBox();
                    final map = s.data!.data() as Map<String, dynamic>?;
                    if (map == null) return const SizedBox();
                    final avg = (map['avg'] ?? 0).toDouble();
                    final count = (map['count'] ?? 0) as int;
                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(avg.toStringAsFixed(1)),
                        const SizedBox(width: 8),
                        Text('($count)'),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reviews list
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('target', isEqualTo: target)
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
                  if (aTs is Timestamp && bTs is Timestamp)
                    return bTs.compareTo(aTs);
                  return 0;
                });

                return Column(
                  children: docsList.map((d) {
                    final r = d.data() as Map<String, dynamic>;
                    final user = (r['user'] ?? r['userId'] ?? 'Anonymous')
                        .toString();
                    final comment = (r['comment'] ?? '').toString();
                    final rating = (r['rating'] ?? 0).toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user),
                        subtitle: Text(comment),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(rating),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('wishlists')
                      .where(
                        'userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                      )
                      .where('targetType', isEqualTo: 'place')
                      .where('targetId', isEqualTo: target)
                      .snapshots(),
                  builder: (sCtx, sSnap) {
                    final isFav = (sSnap.data?.docs.isNotEmpty ?? false);
                    return ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (isFav) {
                            await WishlistService.removeFromWishlist(
                              targetType: 'place',
                              targetId: target,
                            );
                            if (!sCtx.mounted) return;
                            ScaffoldMessenger.of(sCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                              ),
                            );
                          } else {
                            await WishlistService.addToWishlist(
                              targetType: 'place',
                              targetId: target,
                              name: placeName,
                            );
                            if (!sCtx.mounted) return;
                            ScaffoldMessenger.of(sCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Added to wishlist'),
                              ),
                            );
                            Navigator.of(sCtx).pushNamed('/wishlist');
                          }
                        } catch (e) {
                          if (!sCtx.mounted) return;
                          final msg = e.toString();
                          if (msg.contains('permission-denied') ||
                              msg.contains(
                                'Missing or insufficient permissions',
                              )) {
                            ScaffoldMessenger.of(sCtx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Permission denied: check Firestore rules or sign-in status',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(sCtx).showSnackBar(
                              SnackBar(content: Text('Wishlist error: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(isFav ? 'Wishlisted' : 'Add to Wishlist'),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/review',
                      arguments: {'targetType': 'place', 'target': target},
                    );
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Share a Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
