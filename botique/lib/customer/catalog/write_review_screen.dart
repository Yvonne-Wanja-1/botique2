import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animated_star_rating.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/review_repository.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.productId, required this.productName});

  final String productId;
  final String productName;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      showErrorSnack(context, 'Please write a short review before submitting.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final review = await context.read<ReviewRepository>().submit(
            widget.productId,
            rating: _rating,
            comment: comment,
          );
      if (!mounted) return;
      showSuccessSnack(
        context,
        review.isApproved
            ? 'Thank you! Your review has been published.'
            : 'Thank you! Your review was submitted and is awaiting approval.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showErrorSnack(context, 'Could not submit review: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.productName,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Text('Your rating', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Center(
            child: AnimatedStarRating(
              rating: _rating,
              enabled: !_submitting,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$_rating out of 5',
              style: const TextStyle(color: QueensTouchColors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: QueensTouchColors.cream),
                  )
                : const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}