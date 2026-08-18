import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/review_repository.dart';
import '../../models/review.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ReviewRepository>().getPending();
  }

  void _reload() {
    setState(() {
      _future = context.read<ReviewRepository>().getPending();
    });
  }

  Future<void> _approve(Review review) async {
    final ok = await confirmDialog(
      context,
      title: 'Approve review?',
      message: 'This review will be shown publicly on the product page.',
      confirmLabel: 'Yes, approve',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ReviewRepository>().moderate(review.id, approved: true);
      if (!mounted) return;
      _reload();
      showSuccessSnack(context, 'Review approved');
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Approval failed: $e');
    }
  }

  Future<void> _reject(Review review) async {
    final ok = await confirmDialog(
      context,
      title: 'Reject review?',
      message: 'This review will not be shown publicly.',
      confirmLabel: 'Reject',
      isDanger: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ReviewRepository>().moderate(review.id, approved: false);
      if (!mounted) return;
      _reload();
      showSuccessSnack(context, 'Review rejected');
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Rejection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load reviews.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: QueensTouchColors.danger),
              ),
            ),
          );
        }
        final reviews = snapshot.data ?? const <Review>[];
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: reviews.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 80),
                    Center(
                      child: Text(
                        'No reviews pending approval',
                        style: TextStyle(color: QueensTouchColors.textMuted),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) => _ReviewCard(
                    review: reviews[index],
                    onApprove: () => _approve(reviews[index]),
                    onReject: () => _reject(reviews[index]),
                  ),
                ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onApprove, required this.onReject});

  final Review review;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                  child: Text(
                    review.customerName.characters.first,
                    style: const TextStyle(fontSize: 12, color: QueensTouchColors.textDark),
                  ),
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
              ],
            ),
            if (review.productName != null) ...[
              const SizedBox(height: 8),
              Text(
                review.productName!,
                style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(i <= review.rating ? Icons.star : Icons.star_border,
                      size: 16, color: QueensTouchColors.gold),
                const Spacer(),
                Text(
                  'On ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(foregroundColor: QueensTouchColors.danger),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}