import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navbar_widget.dart';
import '../services/contact_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...existing code...
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
          Navigator.pushNamed(context, '/review');
        },
        onTourPlans: () {
          Navigator.pushNamed(context, '/tour-planner');
        },
        onContact: () {
          Navigator.pushNamed(context, '/contact');
        },
        onWishlist: () {
          Navigator.pushNamed(context, '/wishlist');
        }, // <-- Add this
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
      // ...existing code...
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
        child: Center(
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            color: Colors.white.withOpacity(0.97),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, size: 70, color: Color(0xFF1976d2)),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976d2),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to your account to continue',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF1976d2),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });

                              final auth = FirebaseAuth.instance;
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();

                              try {
                                final currentUser = auth.currentUser;
                                if (currentUser != null &&
                                    currentUser.isAnonymous) {
                                  // Try to link anonymous account to email/password
                                  try {
                                    final credential =
                                        EmailAuthProvider.credential(
                                          email: email,
                                          password: password,
                                        );
                                    await currentUser.linkWithCredential(
                                      credential,
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    // If credential already in use, fallback to sign-in
                                    if (e.code == 'credential-already-in-use' ||
                                        e.code == 'email-already-in-use' ||
                                        e.code == 'provider-already-linked') {
                                      await auth.signInWithEmailAndPassword(
                                        email: email,
                                        password: password,
                                      );
                                    } else {
                                      rethrow;
                                    }
                                  }
                                } else {
                                  await auth.signInWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                }

                                // After sign-in (or successful link), claim server threads and sync pending
                                try {
                                  final claimed =
                                      await ContactService.claimServerThreadsForCurrentUser();
                                  if (claimed > 0 && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Claimed $claimed existing conversations.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {}

                                try {
                                  await ContactService.syncPendingMessages();
                                } catch (_) {}

                                Navigator.pushReplacementNamed(context, '/');
                              } on FirebaseAuthException catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Login Failed'),
                                    content: Text(e.message ?? e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Login Failed'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      label: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(fontSize: 16, color: Color(0xFF1976d2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
