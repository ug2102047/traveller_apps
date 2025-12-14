import 'package:flutter/material.dart';
import 'navbar_widget.dart';
import 'footer_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainNavbar(
        onSearch: (query) {},
        onDistrictSelected: (division, district) {
          Navigator.pushNamed(context, '/district_places', arguments: district);
        },
        onPlaceSelected: (category, place) {
          Navigator.pushNamed(context, '/category_places', arguments: category);
        },
        onHotels: () {
          Navigator.pushNamed(context, '/hotels');
        },
        onReview: () {
          Navigator.pushNamed(context, '/all-reviews');
        },
        onTourPlans: () {
          Navigator.pushNamed(context, '/tour-planner');
        },
        onContact: () {
          Navigator.pushNamed(context, '/contact');
        },
        onWishlist: () {
          Navigator.pushNamed(context, '/wishlist');
        },
        onLogin: () {
          Navigator.pushNamed(context, '/login');
        },
        onSignup: () {
          Navigator.pushNamed(context, '/signup');
        },
        onProfile: () {
          Navigator.pushNamed(context, '/profile');
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0D1B2A), // very dark blue
                    Color(0xFF12233E), // dark blue
                    Color(0xFF1B3A5A), // blue slate
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.6, 1.0],
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFe3f2fd), // light sky blue
                    Color(0xFF90caf9), // sky blue
                    Color(0xFF1976d2), // blue
                    Color(0xFFffffff), // white
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.4, 0.8, 1.0],
                ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Card(
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  color: Colors.white.withOpacity(0.97),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore,
                          size: 70,
                          color: const Color(0xFF4285F4),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Where do you want to explore?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Choose a division or category to discover amazing places in Bangladesh.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.map, color: Colors.white),
                            label: const Text(
                              'Divisions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/division');
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.category,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Categories',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40C4FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/category');
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.hotel, color: Colors.white),
                            label: const Text(
                              'Hotels',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/hotels');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1.0),
            FooterWidget(
              onHome: () => Navigator.pushNamed(context, '/'),
              onReview: () => Navigator.pushNamed(context, '/all-reviews'),
              onTourPlans: () => Navigator.pushNamed(context, '/tour-planner'),
              onContact: () => Navigator.pushNamed(context, '/contact'),
              onWishlist: () => Navigator.pushNamed(context, '/wishlist'),
            ),
          ],
        ),
      ),
    );
  }
}
