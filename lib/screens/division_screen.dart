import 'package:flutter/material.dart';

class DivisionScreen extends StatelessWidget {
  final List<Map<String, String>> divisions = [
    {
      'name': 'Dhaka',
      'image': 'assets/dhaka.jpg',
      'desc': 'Dhaka is the capital of bangladesh.',
    },
    {
      'name': 'Chattogram',
      'image': 'assets/chottogram.jpg',
      'desc':
          'Chattogram, gateway to the sea, is famed for its beaches, hills, and the warmth of its people.',
    },
    {
      'name': 'Khulna',
      'image': 'assets/khulna.jpeg',
      'desc':
          'Khulna, home to the Sundarbans, offers serene rivers and the world’s largest mangrove forest.',
    },
    {
      'name': 'Rajshahi',
      'image': 'assets/rajshahi.jpeg',
      'desc':
          'Rajshahi, known as the Silk City, is famous for its mangoes, historical sites, and peaceful ambiance.',
    },
    {
      'name': 'Barishal',
      'image': 'assets/barishal.jpeg',
      'desc':
          'Barishal is famous for its rivers, floating guava gardens, and tranquil rural landscapes.',
    },
    {
      'name': 'Sylhet',
      'image': 'assets/sylhet.jpeg',
      'desc':
          'Sylhet is a land of tea gardens, rolling hills, and natural beauty. Ideal for nature lovers.',
    },
    {
      'name': 'Rangpur',
      'image': 'assets/rangpur.jpeg',
      'desc':
          'Rangpur is known for its rich agricultural lands, historic monuments, and unique local culture.',
    },
    {
      'name': 'Mymensingh',
      'image': 'assets/mymensingh.jpeg',
      'desc':
          'Mymensingh, with its lush landscapes and rivers, offers a calm retreat and rich cultural heritage.',
    },
  ];

  DivisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Divisions of Bangladesh'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: divisions.length,
        itemBuilder: (context, index) {
          final division = divisions[index];
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
                      division['image']!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          division['name']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          division['desc']!,
                          style: const TextStyle(
                            fontSize: 16,
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
                              // Navigate to the correct districts screen for each division
                              switch (division['name']) {
                                case 'Dhaka':
                                  Navigator.pushNamed(
                                    context,
                                    '/division_places',
                                  );
                                  break;
                                case 'Chattogram':
                                  Navigator.pushNamed(
                                    context,
                                    '/chattogram_districts',
                                  );
                                  break;
                                case 'Khulna':
                                  Navigator.pushNamed(
                                    context,
                                    '/khulna_districts',
                                  );
                                  break;
                                case 'Rajshahi':
                                  Navigator.pushNamed(
                                    context,
                                    '/rajshahi_districts',
                                  );
                                  break;
                                case 'Barishal':
                                  Navigator.pushNamed(
                                    context,
                                    '/barishal_districts',
                                  );
                                  break;
                                case 'Sylhet':
                                  Navigator.pushNamed(
                                    context,
                                    '/sylhet_districts',
                                  );
                                  break;
                                case 'Rangpur':
                                  Navigator.pushNamed(
                                    context,
                                    '/rangpur_districts',
                                  );
                                  break;
                                case 'Mymensingh':
                                  Navigator.pushNamed(
                                    context,
                                    '/mymensingh_districts',
                                  );
                                  break;
                                default:
                                  break;
                              }
                            },
                            child: const Text(
                              'View Districts',
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
