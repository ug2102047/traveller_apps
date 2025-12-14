import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onTourPlans;
  final VoidCallback onContact;
  final VoidCallback onWishlist;
  final VoidCallback onHome;

  const FooterWidget({
    required this.onReview,
    required this.onTourPlans,
    required this.onContact,
    required this.onWishlist,
    required this.onHome,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Home',
              child: IconButton(
                onPressed: onHome,
                icon: const Icon(Icons.home, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Review',
              child: IconButton(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Tour Plans',
              child: IconButton(
                onPressed: onTourPlans,
                icon: const Icon(Icons.map, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Contact',
              child: IconButton(
                onPressed: onContact,
                icon: const Icon(Icons.phone, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Wishlist',
              child: IconButton(
                onPressed: onWishlist,
                icon: const Icon(Icons.favorite_border, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
