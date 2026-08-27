import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/product_image_reveal.dart';
import '../../core/animations/product_presentation.dart';
import '../../core/animations/wishlist_heart.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/cart.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistService>();

    if (wishlist.items.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        message: 'Tap the heart on any product to save it here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: wishlist.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _WishlistTile(item: wishlist.items[index]),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.read<WishlistService>();
    final cart = context.read<CartService>();
    final product = item.product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ProductImageReveal(
                imageUrl: product.images.isNotEmpty ? product.images.first : '',
                borderRadius: BorderRadius.circular(12),
                presentation: presentationFor(
                  categorySlug: product.categorySlug,
                  categoryId: product.categoryId,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatKsh(product.effectivePrice),
                    style: const TextStyle(
                      color: QueensTouchColors.plum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            WishlistHeart(
              isSelected: true,
              size: 22,
              onPressed: () => wishlist.remove(product.id),
            ),
            ElevatedButton(
              onPressed: () {
                cart.addProduct(product);
                wishlist.remove(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moved to cart')),
                );
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
