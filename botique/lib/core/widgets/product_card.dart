import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../core/theme/theme.dart';
import '../../services/wishlist_service.dart';
import '../animations/press_scale.dart';
import '../animations/product_image_reveal.dart';
import '../animations/product_presentation.dart';
import '../animations/wishlist_heart.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.heroTag,
  });

  final Product product;
  final bool compact;

  /// Shared-element tag; only set where the product appears exactly once per
  /// screen (e.g. the catalog grid). Home rows pass null to avoid duplicate
  /// Hero tags.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(
      categorySlug: product.categorySlug,
      categoryId: product.categoryId,
    );
    return PressScale(
      onTap: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImageReveal(
                  imageUrl: product.images.isNotEmpty ? product.images.first : '',
                  heroTag: heroTag,
                  presentation: presentation,
                  semanticLabel: product.name,
                  cacheWidth: 640,
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: QueensTouchColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (product.hasLabel(ProductLabel.newArrival))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: QueensTouchColors.plum,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _CardWishlist(productId: product.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\$${product.effectivePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: QueensTouchColors.plum,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.rating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: QueensTouchColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardWishlist extends StatelessWidget {
  const _CardWishlist({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistService>();
    return FutureBuilder<bool>(
      future: wishlist.contains(productId),
      builder: (context, snapshot) {
        final selected = snapshot.data ?? false;
        return Material(
          color: Colors.white.withValues(alpha: 0.85),
          shape: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: WishlistHeart(
              isSelected: selected,
              size: 20,
              onPressed: () => wishlist.toggle(productId),
            ),
          ),
        );
      },
    );
  }
}