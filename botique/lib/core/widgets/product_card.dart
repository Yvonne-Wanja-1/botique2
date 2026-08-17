import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../core/theme/theme.dart';
import '../utils/image_url.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.compact = false});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/product/${product.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ProductImage(product: product),
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QueensTouchColors.blushLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                resolveImageUrl(product.images.first),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
            )
          else
            _placeholder(),
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
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom, size: 40, color: QueensTouchColors.plumLight.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text(
            'No image yet',
            style: TextStyle(color: QueensTouchColors.plumLight.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}