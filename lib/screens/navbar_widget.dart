import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traveller/services/theme_service.dart';

class MainNavbar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String) onSearch;
  final Function(String division, String district) onDistrictSelected;
  final Function(String category, String place) onPlaceSelected;
  final VoidCallback onHotels;
  final VoidCallback onReview;
  final VoidCallback onTourPlans;
  final VoidCallback onContact;
  final VoidCallback onWishlist; // <-- Added
  final VoidCallback? onQa;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onProfile;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  // Example data, replace with your dynamic data if needed
  final Map<String, List<String>> divisions = {
    'Dhaka': ['Dhaka', 'Gazipur', 'Faridpur'],
    'Chattogram': ['Cox\'s Bazar', 'Comilla', 'Feni'],
    // ... add all divisions and districts
  };
  final Map<String, List<String>> categories = {
    'Mosque': ['Shat Gambuj Mosque'],
    'Beach': ['Cox\'s Bazar', 'Kuakata'],
    // ... add all categories and places
  };

  MainNavbar({
    required this.onSearch,
    required this.onDistrictSelected,
    required this.onPlaceSelected,
    required this.onHotels,
    required this.onReview,
    required this.onTourPlans,
    required this.onContact,
    required this.onWishlist, // <-- Added
    this.onQa,
    required this.onLogin,
    required this.onSignup,
    required this.onProfile,
    this.onToggleTheme,
    this.isDarkMode = false,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      titleSpacing: 0,
      title: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final signedIn = snap.hasData && snap.data != null;
          return Row(
            children: [
              const SizedBox(width: 8),

              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 56,
                    ),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        onSubmitted: onSearch,
                        style: const TextStyle(fontSize: 16, height: 1.1),
                        decoration: InputDecoration(
                          hintText: 'Search places, hotels...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Contact button intentionally hidden; keep callback for compatibility
              // TextButton(onPressed: onContact, child: const Text('Contact')),
              const SizedBox(width: 6),
              if (!signedIn) ...[
                Semantics(
                  label: 'Login',
                  child: IconButton(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  label: 'Signup',
                  child: IconButton(
                    onPressed: onSignup,
                    icon: const Icon(
                      Icons.person_add,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ] else ...[
                Semantics(
                  label: 'Profile',
                  child: IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      color: Colors.blueAccent,
                    ),
                    onPressed: onProfile,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              // Theme toggle (reflects ThemeService state)
              Semantics(
                label: 'Toggle theme',
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeService.instance.mode,
                  builder: (context, mode, _) {
                    final dark = mode == ThemeMode.dark;
                    return IconButton(
                      tooltip: 'Toggle dark/light theme',
                      icon: Icon(
                        dark ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.black87,
                      ),
                      onPressed: onToggleTheme ?? ThemeService.instance.toggle,
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: 'Tour Planner',
                child: IconButton(
                  tooltip: 'Tour Planner: what I will do',
                  icon: const Icon(Icons.map, color: Colors.deepOrange),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tour Planner',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'I will suggest a day-by-day itinerary, recommend hotels and restaurants, and provide an estimated cost using live local data. Tap "Open Tour Planner" to start planning.',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onTourPlans();
                                    },
                                    child: const Text('Open Tour Planner'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Semantics(
                label: 'AI Q&A',
                child: IconButton(
                  tooltip: 'AI Q&A: ask questions',
                  icon: const Icon(Icons.question_answer, color: Colors.green),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Q&A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ask general questions and get AI-powered answers. Tap "Open AI Chat" to start.',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      if (onQa != null) return onQa!();
                                      Navigator.pushNamed(context, '/qa');
                                    },
                                    child: const Text('Open AI Chat'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Removed _PlacesDropdown: the left-side 'Places' menu was removed per user request.
