import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/review.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final List<Review> _reviews = [
    Review(
      id: 'r1',
      productId: 'p4',
      customerId: 'c1',
      customerName: 'Amara Okafor',
      rating: 5,
      comment: 'This lipstick is absolutely gorgeous! Long lasting and the shade is perfect.',
      isVerifiedPurchase: true,
      isReported: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Review(
      id: 'r2',
      productId: 'p1',
      customerId: 'c2',
      customerName: 'Zainab Bello',
      rating: 4,
      comment: 'Beautiful dress, fits perfectly. Delivery was quick too.',
      isVerifiedPurchase: true,
      isReported: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Review(
      id: 'r3',
      productId: 'p3',
      customerId: 'c9',
      customerName: 'Unknown User',
      rating: 2,
      comment: 'Not worth the price honestly. (Flagged for review)',
      isVerifiedPurchase: false,
      isReported: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Review(
      id: 'r4',
      productId: 'p8',
      customerId: 'c4',
      customerName: 'Tina Adeyemi',
      rating: 5,
      comment: 'My skin has never looked better. This serum is magic!',
      isVerifiedPurchase: true,
      isReported: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final reported = _reviews.where((r) => r.isReported).toList();
    final others = _reviews.where((r) => !r.isReported).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (reported.isNotEmpty) ...[
          Text('Reported', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final r in reported) _ReviewCard(review: r, reported: true, onDelete: () => _delete(r.id)),
          const SizedBox(height: 16),
        ],
        Text('All Reviews', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final r in others) ...[
          _ReviewCard(review: r, onDelete: () => _delete(r.id)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _delete(String id) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete review?',
      message: 'This will permanently remove the review.',
      isDanger: true,
    );
    if (!ok) return;
    setState(() => _reviews.removeWhere((r) => r.id == id));
    showSuccessSnack(context, 'Review deleted');
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.reported = false, required this.onDelete});

  final Review review;
  final bool reported;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: reported ? QueensTouchColors.danger.withValues(alpha: 0.04) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: QueensTouchColors.blush,
                  child: Text(review.customerName.characters.first, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (review.isVerifiedPurchase)
                  const Icon(Icons.verified, size: 16, color: QueensTouchColors.success),
                if (reported)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: QueensTouchColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Reported', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(i <= review.rating ? Icons.star : Icons.star_border, size: 16, color: QueensTouchColors.gold),
                const Spacer(),
                Text(
                  'On ${review.createdAt.day}/${review.createdAt.month}',
                  style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: QueensTouchColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}