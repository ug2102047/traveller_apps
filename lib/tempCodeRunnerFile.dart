import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // This file is generated when you set up Firebase

// Import your custom screens
import 'screens/destination_listing_screen.dart';
import 'screens/hotel_listing_screen.dart';
import 'screens/hotel_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/my_wishlist_screen.dart';
import 'screens/support_tickets_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/review_form_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traveller App',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/destinations': (context) => const DestinationListingScreen(),
        '/hotels': (context) => const HotelListingScreen(),
        '/hotel-details': (context) => const HotelDetailsScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const MyProfileScreen(),
        '/bookings': (context) => const MyBookingsScreen(),
        '/wishlist': (context) => const MyWishlistScreen(),
        '/support': (context) => const SupportTicketsScreen(),
        '/booking-form': (context) => const BookingFormScreen(),
        '/review': (context) => const ReviewFormScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Authenticated user: show Destination Listing
            return const DestinationListingScreen();
          } else {
            // Guest user: show HomeScreen with Login/Signup
            return const HomeScreen();
          }
        },
      ),
    );
  }
}
