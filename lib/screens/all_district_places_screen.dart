import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/spots.dart';

class AllDistrictPlacesScreen extends StatelessWidget {
  final String districtName;
  const AllDistrictPlacesScreen({required this.districtName, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$districtName Places'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('district', isEqualTo: districtName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final remoteDocs = (snapshot.data as QuerySnapshot?)?.docs ?? [];
          final remotePlaces = remoteDocs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          // Local spots for this district.
          // Accept common spelling/spacing variants (e.g., Barishal vs Barisal,
          // Bogura vs Bogra, Chapai Nawabganj vs Chapainawabganj).
          String _alias(String name) {
            final n = name.trim().toLowerCase();
            if (n == 'barishal') return 'barisal';
            if (n == 'bogura' || n == 'bogura ') return 'bogra';
            if (n == 'bogra') return 'bogra';
            if (n == 'chapai nawabganj' ||
                n == 'chapai-nawabganj' ||
                n == 'chapainawabganj')
              return 'chapainawabganj';
            // Normalize common spelling variants for Sylhet-region and others
            if (n == 'netrokona') return 'netrakona';
            if (n == 'netrakona') return 'netrakona';
            if (n == 'moulavibazar') return 'moulvibazar';
            if (n == 'moulvibazar') return 'moulvibazar';
            return n;
          }

          final districtLower = districtName.trim().toLowerCase();
          final aliasLower = _alias(districtName);

          final localMatches = spots.where((s) {
            final sd = (s['district'] ?? '').toString().toLowerCase();
            return sd == districtLower || sd == aliasLower;
          }).toList();

          // Merge remote and local, avoid duplicates by id/name
          final merged = <Map<String, dynamic>>[];
          final seen = <String>{};
          for (final p in remotePlaces) {
            final key = (p['id'] ?? p['name'] ?? '').toString();
            if (!seen.contains(key)) {
              merged.add(p);
              seen.add(key);
            }
          }
          for (final p in localMatches) {
            final key = (p['id'] ?? p['name'] ?? '').toString();
            if (!seen.contains(key)) {
              merged.add(p);
              seen.add(key);
            }
          }

          if (merged.isEmpty) {
            return Center(child: Text('No places found for $districtName.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: merged.length,
            itemBuilder: (context, index) {
              final place = merged[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 24),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place['category'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if (place['image'] != null && place['image'] != '')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Builder(
                            builder: (ctx) {
                              final img = place['image'].toString();
                              if (img.startsWith('http')) {
                                return Image.network(
                                  img,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, st) => const SizedBox(),
                                );
                              }
                              return Image.asset(
                                img,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/place_details',
                              arguments: place,
                            );
                          },
                          child: const Text('View Details'),
                        ),
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
