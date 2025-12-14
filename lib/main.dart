import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/contact_service.dart';
import 'services/theme_service.dart';
import 'utils/local_bookings.dart';

// Import your custom screens
import 'screens/destination_listing_screen.dart';
import 'screens/hotel_listing_screen.dart';
import 'screens/hotel_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_choice_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_contacts_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/my_wishlist_screen.dart';
import 'screens/support_tickets_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/review_form_screen.dart';
import 'screens/admin_bookings_screen.dart';
import 'screens/home_screen.dart';
import 'screens/division_screen.dart';
import 'screens/category_screen.dart';
import 'screens/districts_screen.dart';
import 'screens/category_places_screen.dart';
// district screens consolidated into `districts_screen.dart`
import 'screens/place_details_screen.dart';
import 'screens/all_district_places_screen.dart'; // Use this for all districts
import 'screens/all_reviews_screen.dart';
import 'screens/my_conversations_screen.dart';
import 'screens/check_email_screen.dart';
// Tour planner feature removed
import 'screens/qa_screen.dart';
import 'screens/faridpur_spots_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize theme service before running the app so theme is available synchronously
  await ThemeService.instance.init();
  try {
    print('Firebase initialized successfully');
    // Ensure an anonymous user is signed in so debug writes work
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        print('Signed in anonymously: ${auth.currentUser?.uid}');
      } else {
        print('Already signed in: ${auth.currentUser?.uid}');
      }
    } catch (e) {
      print('Anonymous sign-in failed: $e');
    }
    // Attempt to sync any locally saved pending contact messages
    try {
      final res = await ContactService.syncPendingMessages();
      print('ContactService.syncPendingMessages result: $res');
    } catch (e) {
      print('Error syncing pending contact messages: $e');
    }
    // Attempt to sync any locally stored bookings
    try {
      await syncLocalBookings();
      print('Local bookings sync attempted');
    } catch (e) {
      print('Error syncing local bookings: $e');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, // <-- Remove the DEBUG banner
          title: 'Traveller App',
          // Light theme (cards and background as normal)
          theme: ThemeData.light().copyWith(primaryColor: Colors.blue),
          // Dark theme: keep card colors the same as light mode (white)
          // and only change scaffold/background to black so cards retain their appearance.
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
            canvasColor: Colors.black,
            // Keep cards white so the cards look identical in both themes
            cardColor: Colors.white,
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            // Keep app bars similar to light theme where appropriate
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          themeMode: themeMode,
          // Each screen provides its own AppBar/footer. Do not inject a global
          // navbar/footer here to avoid duplicate bars appearing on screens that
          // already set `appBar` or `bottomNavigationBar` in their `Scaffold`.
          routes: {
            '/destinations': (context) => const DestinationListingScreen(),
            '/hotels': (context) => const HotelListingScreen(),
            '/hotel-details': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              return HotelDetailsScreen(hotel: args);
            },
            '/login': (context) => const RoleChoiceScreen(),
            '/user-login': (context) => const LoginScreen(),
            '/admin-login': (context) => const AdminLoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/profile': (context) => const MyProfileScreen(),
            '/bookings': (context) => const MyBookingsScreen(),
            '/wishlist': (context) => const MyWishlistScreen(),
            '/support': (context) => const SupportTicketsScreen(),
            '/booking-form': (context) => const BookingFormScreen(),
            '/review': (context) => const ReviewFormScreen(),
            '/all-reviews': (context) => const AllReviewsScreen(),
            '/admin-bookings': (context) => const AdminBookingsScreen(),
            '/admin-home': (context) => const AdminHomeScreen(),
            '/admin-contacts': (context) => const AdminContactsScreen(),
            '/contact': (context) => const ContactScreen(),
            '/division': (context) => DivisionScreen(),
            '/category': (context) => CategoryScreen(),
            '/division_places': (context) => const DistrictsScreen(
              collection: 'dhaka_districts',
              title: 'Dhaka',
            ),
            '/category_places': (context) => CategoryPlacesScreen(),
            '/chattogram_districts': (context) => const DistrictsScreen(
              collection: 'chattogram_districts',
              title: 'Chattogram',
            ),
            '/khulna_districts': (context) => const DistrictsScreen(
              collection: 'khulna_districts',
              title: 'Khulna',
            ),
            '/rajshahi_districts': (context) => const DistrictsScreen(
              collection: 'rajshahi_districts',
              title: 'Rajshahi',
            ),
            '/barishal_districts': (context) => const DistrictsScreen(
              collection: 'barishal_districts',
              title: 'Barishal',
            ),
            '/sylhet_districts': (context) => const DistrictsScreen(
              collection: 'sylhet_districts',
              title: 'Sylhet',
            ),
            '/rangpur_districts': (context) => const DistrictsScreen(
              collection: 'rangpur_districts',
              title: 'Rangpur',
            ),
            '/mymensingh_districts': (context) => const DistrictsScreen(
              collection: 'mymensingh_districts',
              title: 'Mymensingh',
            ),
            // Use the new all-district places screen for all districts
            '/district_places': (context) {
              final districtName =
                  ModalRoute.of(context)!.settings.arguments as String;
              return AllDistrictPlacesScreen(districtName: districtName);
            },
            '/place_details': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return PlaceDetailsScreen(place: args);
            },
            '/my-conversations': (context) => const MyConversationsScreen(),
            // Tour planner route removed
            '/qa': (context) => const QaScreen(),
            '/faridpur-spots': (context) => const FaridpurSpotsScreen(),
            '/check-email': (context) => const CheckEmailScreen(),
          },
          // Always show the `HomeScreen` as the main entry UI so the app looks
          // the same before and after login. Individual screens can still
          // check auth when they need it.
          home: const HomeScreen(),
        );
      },
    );
  }
}
