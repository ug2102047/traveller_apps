import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/wishlist_service.dart';
import '../data/hotels.dart';

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371.0; // km
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);

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
        title: Text(placeName.isNotEmpty ? placeName : "Place Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //------------------------------
            // PLACE IMAGE
            //------------------------------
            if ((place['image'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: place['image'].toString().startsWith("http")
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

            //------------------------------
            // NAME & DESCRIPTION
            //------------------------------
            Text(
              placeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              (place['description'] ?? '').toString(),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            //------------------------------
            // REVIEW HEADER + AVERAGE
            //------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Reviews",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ratings')
                      .doc(target)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data == null) {
                      return const SizedBox();
                    }

                    final map = snap.data!.data() as Map<String, dynamic>?;
                    if (map == null) return const SizedBox();

                    final avg = (map['avg'] ?? 0).toDouble();
                    final count = (map['count'] ?? 0) as int;

                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(avg.toStringAsFixed(1)),
                        const SizedBox(width: 6),
                        Text("($count)"),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            //------------------------------
            // REVIEWS LIST
            //------------------------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where("target", isEqualTo: target)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Text("Error: ${snap.error}");
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text("No reviews yet.");
                }

                final sorted = List<QueryDocumentSnapshot>.from(docs);
                sorted.sort((a, b) {
                  final aMap = a.data() as Map<String, dynamic>;
                  final bMap = b.data() as Map<String, dynamic>;

                  final aTs = aMap['created_at'];
                  final bTs = bMap['created_at'];

                  if (aTs is Timestamp && bTs is Timestamp) {
                    return bTs.compareTo(aTs);
                  }
                  return 0;
                });

                return Column(
                  children: sorted.map((d) {
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
                            const SizedBox(width: 4),
                            Text(rating),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            //------------------------------
            // NEARBY HOTELS
            //------------------------------
            Builder(
              builder: (ctx) {
                double? pLat;
                double? pLng;
                final latV = place['latitude'];
                final lngV = place['longitude'];
                if (latV is double) pLat = latV;
                if (latV is int) pLat = latV.toDouble();
                if (lngV is double) pLng = lngV;
                if (lngV is int) pLng = lngV.toDouble();

                final nearby = <Map<String, dynamic>>[];
                if (pLat != null && pLng != null) {
                  for (final h in hotels) {
                    final hLat = (h['latitude'] as num?)?.toDouble();
                    final hLng = (h['longitude'] as num?)?.toDouble();
                    if (hLat == null || hLng == null) continue;
                    final d = _distanceKm(pLat, pLng, hLat, hLng);
                    if (d <= 50.0) {
                      final copy = Map<String, dynamic>.from(h);
                      copy['distance_km'] = d;
                      nearby.add(copy);
                    }
                  }
                  nearby.sort(
                    (a, b) => (a['distance_km'] as double).compareTo(
                      b['distance_km'] as double,
                    ),
                  );
                }

                if (nearby.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Hotels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: nearby.length,
                        itemBuilder: (c, i) {
                          final h = nearby[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed('/hotel-details', arguments: h),
                            child: Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 12),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if ((h['image'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          h['image'],
                                          width: 100,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (a, b, c) =>
                                              const SizedBox(
                                                width: 100,
                                                height: 140,
                                              ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              h['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              h['price_range'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (h['rating'] ?? '')
                                                      .toString(),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${(h['distance_km'] as double).toStringAsFixed(1)} km',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),

            //------------------------------
            // ACTION BUTTONS
            //------------------------------
            Row(
              children: [
                //---------------------------
                // WISHLIST BUTTON
                //---------------------------
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
                  builder: (ctx, sSnap) {
                    final isFav = (sSnap.data?.docs.isNotEmpty ?? false);

                    return ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (isFav) {
                            await WishlistService.removeFromWishlist(
                              targetType: 'place',
                              targetId: target,
                            );

                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text("Removed from wishlist"),
                              ),
                            );
                          } else {
                            await WishlistService.addToWishlist(
                              targetType: 'place',
                              targetId: target,
                              name: placeName,
                            );

                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text("Added to wishlist"),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(isFav ? "Wishlisted" : "Add to Wishlist"),
                    );
                  },
                ),

                const SizedBox(width: 12),

                //---------------------------
                // ADD REVIEW BUTTON
                //---------------------------
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/review',
                      arguments: {'targetType': 'place', 'target': target},
                    );
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text("Share Review"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
