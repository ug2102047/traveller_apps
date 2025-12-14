import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/spots.dart';

class CategoryPlacesScreen extends StatelessWidget {
  const CategoryPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String categoryName =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Places'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Build list combining Firestore results and local Faridpur data
          final remoteDocs = (snapshot.data as QuerySnapshot?)?.docs ?? [];
          final remotePlaces = remoteDocs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          // Find local spots that match this category (across districts)
          final localMatches = spots
              .where((s) => (s['category'] ?? '') == categoryName)
              .toList();

          // Merge remote and local, avoid duplicates by 'id' or 'name'
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
            return Center(child: Text('No places found for $categoryName.'));
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
                        place['district'] ?? '',
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
                          child: Image.asset(
                            place['image'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
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
