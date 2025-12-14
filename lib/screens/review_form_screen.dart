import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/review_service.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic> _args = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _args = args;
  }

  Widget _star(int index) {
    final filled = index <= _rating;
    return GestureDetector(
      onTap: () => setState(() => _rating = index),
      child: Icon(
        Icons.star,
        color: filled ? Colors.amber : Colors.grey.shade300,
        size: 36,
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }
    setState(() => _loading = true);
    try {
      final targetType = (_args['targetType'] ?? 'place').toString();
      final target = (_args['target'] ?? '').toString();
      if (target.isEmpty) throw Exception('Missing target');

      await ReviewService.submitReview(
        targetType: targetType,
        target: target,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      // Unwrap common boxed/converted Future errors and show a friendly
      // message. Also log the full error + stack to console for debugging.
      String msg = 'Failed to submit review.';
      try {
        if (e is FirebaseException) {
          msg = e.message ?? e.toString();
        } else if (e is Error) {
          msg = e.toString();
        } else {
          // Some errors are boxed (e.g. from isolates or converted futures)
          // and expose an `error` property. Try to read common fields.
          final dynamic de = e;
          if (de != null) {
            if (de is Map && de['error'] != null) {
              msg = de['error'].toString();
            } else if ((de).error != null) {
              msg = (de).error.toString();
            } else if ((de).message != null) {
              msg = (de).message.toString();
            } else {
              msg = de.toString();
            }
          }
        }
      } catch (_) {
        msg = e.toString();
      }

      // Log details for debugging
      // ignore: avoid_print
      debugPrint('Review submit error: $e');
      // ignore: avoid_print
      debugPrint('$st');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit review: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = (_args['target'] ?? '').toString();
    final targetType = (_args['targetType'] ?? 'place').toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For: $targetType — $target',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(children: List.generate(5, (i) => _star(i + 1))),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your experience...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
