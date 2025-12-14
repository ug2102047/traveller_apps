import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/wishlist_service.dart';

class MyWishlistScreen extends StatelessWidget {
  const MyWishlistScreen({super.key});

  // ---------- Hydrate Place ----------
  Future<Map<String, dynamic>> _hydratePlace(Map<String, dynamic> m) async {
    var data = Map<String, dynamic>.from(m);

    final hasDetails =
        (m['description'] != null && m['description'].toString().isNotEmpty) ||
        (m['image'] != null && m['image'].toString().isNotEmpty);

    if (hasDetails) return data;

    final targetId = (m['targetId'] ?? m['name'] ?? '').toString();

    try {
      if (targetId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('places')
            .doc(targetId)
            .get();

        if (doc.exists && doc.data() != null) {
          return Map<String, dynamic>.from(doc.data()!);
        }

        final q = await FirebaseFirestore.instance
            .collection('places')
            .where('name', isEqualTo: m['name'])
            .limit(1)
            .get();

        if (q.docs.isNotEmpty) {
          return Map<String, dynamic>.from(q.docs.first.data());
        }
      }
    } catch (_) {}

    return data;
  }

  // ---------- Hydrate Hotel ----------
  Future<Map<String, dynamic>> _hydrateHotel(Map<String, dynamic> m) async {
    var data = Map<String, dynamic>.from(m);

    final hasDetails =
        (m['description'] != null && m['description'].toString().isNotEmpty) ||
        (m['image'] != null && m['image'].toString().isNotEmpty);

    if (hasDetails) return data;

    final targetId = (m['targetId'] ?? m['name'] ?? '').toString();

    try {
      if (targetId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('hotels')
            .doc(targetId)
            .get();

        if (doc.exists && doc.data() != null) {
          return Map<String, dynamic>.from(doc.data()!);
        }

        final q = await FirebaseFirestore.instance
            .collection('hotels')
            .where('name', isEqualTo: m['name'])
            .limit(1)
            .get();

        if (q.docs.isNotEmpty) {
          return Map<String, dynamic>.from(q.docs.first.data());
        }
      }
    } catch (_) {}

    return data;
  }

  // ---------- PLACE CARD ----------
  Widget _placeCard(BuildContext context, QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;

    final name = m['name'] ?? m['targetId'] ?? '';
    final extra = m['extra'] as Map<String, dynamic>?;

    final district = m['district'] ?? extra?['district'] ?? '';
    final description = m['description'] ?? extra?['description'] ?? '';
    final image = m['image'] ?? extra?['image'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (district.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            district.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      if (description.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            description.toString(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await d.reference.delete();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Removed")));
                  },
                ),
              ],
            ),
            if (image.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.toString().startsWith("http")
                      ? Image.network(image, height: 180, fit: BoxFit.cover)
                      : Image.asset(image, height: 180, fit: BoxFit.cover),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final full = await _hydratePlace(m);
                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/place_details',
                    arguments: full,
                  );
                },
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- HOTEL CARD ----------
  Widget _hotelCard(BuildContext context, QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;

    final name = m['name'] ?? m['targetId'] ?? '';
    final extra = m['extra'] as Map<String, dynamic>?;

    final description = m['description'] ?? extra?['description'] ?? '';
    final image = m['image'] ?? extra?['image'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hotel, color: Colors.orange, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            description.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await d.reference.delete();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Removed")));
                  },
                ),
              ],
            ),
            if (image.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.toString().startsWith("http")
                      ? Image.network(image, height: 160, fit: BoxFit.cover)
                      : Image.asset(image, height: 160, fit: BoxFit.cover),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final full = await _hydrateHotel(m);
                    if (!context.mounted) return;
                    Navigator.pushNamed(
                      context,
                      '/hotel-details',
                      arguments: full,
                    );
                  },
                  child: const Text("View Details"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Sign in to see your wishlist")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Places",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: WishlistService.streamWishlistForType("place"),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Text("Error: ${snap.error}");

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Text("No places in wishlist");

                return Column(
                  children: docs.map((d) => _placeCard(context, d)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Hotels",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: WishlistService.streamWishlistForType("hotel"),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Text("Error: ${snap.error}");

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Text("No hotels in wishlist");

                return Column(
                  children: docs.map((d) => _hotelCard(context, d)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
