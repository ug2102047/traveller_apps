import 'package:flutter/material.dart';
import '../data/spots.dart';

class FaridpurSpotsScreen extends StatelessWidget {
  const FaridpurSpotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faridpur Spots')),
      body: ListView.builder(
        itemCount: spots
            .where(
              (s) =>
                  (s['district'] ?? '').toString().toLowerCase() == 'faridpur',
            )
            .length,
        itemBuilder: (context, index) {
          final list = spots
              .where(
                (s) =>
                    (s['district'] ?? '').toString().toLowerCase() ==
                    'faridpur',
              )
              .toList();
          final spot = list[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.place, color: Colors.blue),
              title: Text(spot['name'] ?? ''),
              subtitle: Text(
                spot['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(spot['name'] ?? ''),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spot['description'] ?? ''),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${spot['latitude']}, Long: ${spot['longitude']}',
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
