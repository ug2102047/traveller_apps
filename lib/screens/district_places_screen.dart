import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictPlacesScreen extends StatelessWidget {
  final String districtName;
  const DistrictPlacesScreen({super.key, required this.districtName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$districtName Places')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('district', isEqualTo: districtName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              (snapshot.data! as QuerySnapshot).docs.isEmpty) {
            return Center(child: Text('No places found for $districtName.'));
          }
          final places = (snapshot.data! as QuerySnapshot).docs;
          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: place['image'] != null
                      ? Image.asset(
                          place['image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : null,
                  title: Text(place['name'] ?? ''),
                  subtitle: Text(place['description'] ?? ''),
                  onTap: () {
                    // You can navigate to a detailed place screen here if you want
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
