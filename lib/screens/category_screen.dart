import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final List<Map<String, String>> categories = [
    // Ordered exactly as requested
    {
      'name': 'Island',
      'image': 'assets/island.jpg',
      'desc': 'Explore the beautiful islands of Bangladesh.',
    },
    {
      'name': 'Beach',
      'image': 'assets/beach.jpg',
      'desc': 'Discover the stunning beaches for relaxation and adventure.',
    },
    {
      'name': 'Amusement Park',
      'image': 'assets/amusement_park.jpg',
      'desc': 'Fun-filled amusement parks for family and friends.',
    },
    {
      'name': 'Waterfall',
      'image': 'assets/waterfall.jpg',
      'desc': 'Experience breathtaking waterfalls across the country.',
    },
    {
      'name': 'River',
      'image': 'assets/river.jpg',
      'desc': 'Enjoy the scenic beauty of Bangladesh\'s famous rivers.',
    },
    {
      'name': 'Temple',
      'image': 'assets/temple.jpg',
      'desc': 'Visit historic and spiritual temples.',
    },
    {
      'name': 'Mosque',
      'image': 'assets/mosque.jpg',
      'desc': 'Explore the architectural wonders of mosques.',
    },
    {
      'name': 'Historical Places',
      'image': 'assets/historical.jpg',
      'desc': 'Step back in time at historical landmarks and sites.',
    },
    {
      'name': 'Others',
      'image': 'assets/others.jpg',
      'desc': 'Discover other unique attractions and destinations.',
    },
  ];

  CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Categories of Bangladesh'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      category['image'] ?? '',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['desc'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/category_places',
                                arguments: category['name'],
                              );
                            },
                            child: const Text(
                              'View Places',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
