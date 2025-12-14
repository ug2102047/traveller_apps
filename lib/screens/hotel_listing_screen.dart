import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/hotels.dart';

bool _isNetworkUrl(String? s) =>
    s != null && (s.startsWith('http') || s.startsWith('https'));

/// Debug helper: seed some sample hotels into Firestore (only in debug builds)
Future<void> _seedSampleHotels(BuildContext context) async {
  if (!kDebugMode) return;
  final examples = [
    {
      'name': 'Shat Gambuj Guest House',
      'short_description': 'Cozy stay near the historic masjid',
      'description':
          'A comfortable guest house within walking distance of Shat Gambuj Masjid.',
      'price_range': '৳800-1,500',
      'contact': '+8801700000001',
      'address': 'Near Shat Gambuj Masjid, Bagerhat',
      'place': 'Shat Gambuj Masjid',
      'image':
          'https://images.unsplash.com/photo-1501117716987-c8e3f7f8d9d9?auto=format&fit=crop&w=800&q=60',
    },
    {
      'name': 'Bagerhat River View Hotel',
      'short_description': 'Modern rooms with river views',
      'description':
          'Clean, modern rooms and friendly staff close to heritage sites.',
      'price_range': '৳1,200-2,500',
      'contact': '+8801700000002',
      'address': 'Riverside, Bagerhat',
      'place': 'Bagerhat Museum',
      'image':
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=60',
    },
    {
      'name': 'Royal Business Hotel',
      'short_description': 'Business-friendly hotel with free Wi-Fi',
      'description': 'Ideal for business travelers; near transport and dining.',
      'price_range': '৳2,000-4,000',
      'contact': '+8801700000003',
      'address': 'Central Khulna',
      'place': 'Khulna Central',
      'image':
          'https://images.unsplash.com/photo-1560347876-aeef00ee58a1?auto=format&fit=crop&w=800&q=60',
    },
  ];

  try {
    for (final h in examples) {
      await FirebaseFirestore.instance.collection('hotels').add({
        ...h,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed completed'),
        content: const Text('Sample hotels were written to Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed failed'),
        content: SingleChildScrollView(child: Text(e.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Debug helper: backfill `place_key` for existing hotel documents.
Future<void> _backfillPlaceKeys(BuildContext context) async {
  if (!kDebugMode) return;
  try {
    final snap = await FirebaseFirestore.instance.collection('hotels').get();
    final batch = FirebaseFirestore.instance.batch();
    String normalize(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final doc in snap.docs) {
      final data = doc.data();
      final place = (data['place'] ?? '').toString();
      final key = normalize(place);
      batch.update(doc.reference, {'place_key': key});
    }
    await batch.commit();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backfill completed'),
        content: const Text('place_key added/updated for existing hotels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backfill failed'),
        content: SingleChildScrollView(child: Text(e.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class HotelListingScreen extends StatelessWidget {
  const HotelListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotels')),
      body: StreamBuilder<QuerySnapshot>(
        // Use a collectionGroup query to include hotels saved either at
        // the top-level `hotels` collection or as a `hotels` subcollection
        // under place documents. This lets the Hotels page show any
        // nearby/subcollection hotels as well.
        stream: FirebaseFirestore.instance
            .collectionGroup('hotels')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading hotels: ${snapshot.error}'),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          // Build a combined list: local hotels (from `hotels.dart`) first, then remote documents.
          final items = <Map<String, dynamic>>[];
          for (final h in hotels) {
            final copy = Map<String, dynamic>.from(h);
            copy['_source'] = 'local';
            items.add(copy);
          }
          for (final docSnap in docs) {
            final hotel =
                (docSnap.data() as Map<String, dynamic>?) ??
                <String, dynamic>{};
            final copy = Map<String, dynamic>.from(hotel);
            copy['_source'] = 'remote';
            copy['_id'] = docSnap.id;
            items.add(copy);
          }

          if (items.isEmpty) {
            return const Center(child: Text('No hotels added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final imageVal = (item['image'] ?? '') as String;

              Widget leading;
              if (_isNetworkUrl(imageVal)) {
                leading = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageVal,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 96,
                      height: 96,
                      color: Colors.grey[200],
                      child: const Icon(Icons.hotel, color: Colors.grey),
                    ),
                  ),
                );
              } else if (imageVal.isNotEmpty) {
                leading = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imageVal,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 96,
                      height: 96,
                      color: Colors.grey[200],
                      child: const Icon(Icons.hotel, color: Colors.grey),
                    ),
                  ),
                );
              } else {
                leading = Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hotel, color: Colors.blue),
                );
              }

              final hotelName = (item['name'] as String?)?.trim();
              final displayName = (hotelName != null && hotelName.isNotEmpty)
                  ? hotelName
                  : (item['_id'] ?? 'Unnamed');
              final placeName =
                  (item['place'] ?? item['place_key'] ?? '') as String;
              final shortDesc =
                  (item['short_description'] ?? item['description'] ?? '')
                      as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: leading,
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    (shortDesc.isNotEmpty ? shortDesc : placeName),
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed('/hotel-details', arguments: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _normalizePlaceKey(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

Future<void> _showAddCoxsBazarDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final nameCtl = TextEditingController();
  final shortCtl = TextEditingController();
  final priceCtl = TextEditingController();
  final contactCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final imageCtl = TextEditingController();

  final placeName = "Cox's Bazar";
  final placeKey = _normalizePlaceKey(placeName);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Add hotel near Cox's Bazar"),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Hotel name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: shortCtl,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                ),
              ),
              TextFormField(
                controller: priceCtl,
                decoration: const InputDecoration(labelText: 'Price / range'),
              ),
              TextFormField(
                controller: contactCtl,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
              TextFormField(
                controller: addressCtl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: imageCtl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Place: $placeName')),
                  const SizedBox(width: 8),
                  Text('key: $placeKey', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final data = {
              'name': nameCtl.text.trim(),
              'short_description': shortCtl.text.trim(),
              'description': shortCtl.text.trim(),
              'price_range': priceCtl.text.trim(),
              'contact': contactCtl.text.trim(),
              'address': addressCtl.text.trim(),
              'place': placeName,
              'place_key': placeKey,
              'image': imageCtl.text.trim(),
              'created_at': FieldValue.serverTimestamp(),
            };
            try {
              await FirebaseFirestore.instance.collection('hotels').add(data);
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (okCtx) => AlertDialog(
                  title: const Text('Success'),
                  content: const Text('Hotel added for Cox\'s Bazar.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(okCtx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } catch (e) {
              showDialog(
                context: context,
                builder: (errCtx) => AlertDialog(
                  title: const Text('Failed'),
                  content: SingleChildScrollView(child: Text(e.toString())),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(errCtx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
