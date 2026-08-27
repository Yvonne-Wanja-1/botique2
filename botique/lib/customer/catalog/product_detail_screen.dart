import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/animations/add_to_cart_fly.dart';
import '../../core/animations/product_image_reveal.dart';
import '../../core/animations/product_presentation.dart';
import '../../core/animations/qts_animation.dart';
import '../../core/animations/shade_selector.dart';
import '../../core/animations/wishlist_heart.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/repositories/review_repository.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/cart_service.dart';
import '../../services/catalog_service.dart';
import '../../services/wishlist_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _productFuture;
  late Future<List<Review>> _reviewsFuture;
  late Future<ReviewEligibility> _eligibilityFuture;

  String? _selectedSize;
  String? _selectedColor;
  String? _selectedShade;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = context.read<CatalogService>().getProduct(widget.productId);
    _reviewsFuture = context.read<CatalogService>().getReviews(widget.productId);
    _eligibilityFuture = context.read<ReviewRepository>().getEligibility(widget.productId);
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = context.read<CatalogService>().getReviews(widget.productId);
      _eligibilityFuture = context.read<ReviewRepository>().getEligibility(widget.productId);
    });
  }

  Future<void> _openWriteReview(Product product) async {
    final submitted = await context.push<bool>(
      '/product/${widget.productId}/review',
      extra: product.name,
    );
    if (submitted == true) {
      _refreshReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                _GalleryHeroShell(productId: widget.productId),
                const Expanded(child: LoadingView()),
              ],
            );
          }
          final product = snapshot.data;
          if (product == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Product not found',
            );
          }
          return _ProductDetailBody(
            product: product,
            reviewsFuture: _reviewsFuture,
            eligibilityFuture: _eligibilityFuture,
            onWriteReview: () => _openWriteReview(product),
            selectedSize: _selectedSize,
            selectedColor: _selectedColor,
            selectedShade: _selectedShade,
            quantity: _quantity,
            onSizeSelected: (v) => setState(() => _selectedSize = v),
            onColorSelected: (v) => setState(() => _selectedColor = v),
            onShadeSelected: (v) => setState(() => _selectedShade = v),
            onQuantityChanged: (v) => setState(() => _quantity = v),
          );
        },
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.reviewsFuture,
    required this.eligibilityFuture,
    required this.onWriteReview,
    required this.selectedSize,
    required this.selectedColor,
    required this.selectedShade,
    required this.quantity,
    required this.onSizeSelected,
    required this.onColorSelected,
    required this.onShadeSelected,
    required this.onQuantityChanged,
  });

  final Product product;
  final Future<List<Review>> reviewsFuture;
  final Future<ReviewEligibility> eligibilityFuture;
  final VoidCallback onWriteReview;
  final String? selectedSize;
  final String? selectedColor;
  final String? selectedShade;
  final int quantity;
  final ValueChanged<String?> onSizeSelected;
  final ValueChanged<String?> onColorSelected;
  final ValueChanged<String?> onShadeSelected;
  final ValueChanged<int> onQuantityChanged;

  /// The variant matching every selection (size/color/shade), or null when
  /// nothing is selected or no variant matches. Passing it makes the cart line
  /// carry the chosen shade (and size/color).
  ProductVariant? _selectedVariant(Product product) {
    if (selectedSize == null && selectedColor == null && selectedShade == null) {
      return null;
    }
    for (final v in product.variants) {
      if ((selectedSize == null || v.size == selectedSize) &&
          (selectedColor == null || v.color == selectedColor) &&
          (selectedShade == null || v.shade == selectedShade)) {
        return v;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final wishlist = context.watch<WishlistService>();
    final sizes = product.variants.where((v) => v.size != null).map((v) => v.size!).toSet().toList();
    final colors = product.variants.where((v) => v.color != null).map((v) => v.color!).toSet().toList();
    final shades = product.variants.where((v) => v.shade != null).map((v) => v.shade!).toSet().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Gallery(product: product),
        const SizedBox(height: 16),
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _RatingSummary(product: product, reviewsFuture: reviewsFuture),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatKsh(product.effectivePrice),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: QueensTouchColors.plum,
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  formatKsh(product.price),
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: QueensTouchColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Save ${product.discountPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: QueensTouchColors.danger, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (sizes.isNotEmpty) _VariantSection(
          label: 'Select Size',
          options: sizes,
          selected: selectedSize,
          onSelect: onSizeSelected,
        ),
        if (colors.isNotEmpty) _VariantSection(
          label: 'Select Color',
          options: colors,
          selected: selectedColor,
          onSelect: onColorSelected,
        ),
        if (shades.isNotEmpty) ...[
          ShadeSelector(
            shades: shades,
            selected: selectedShade,
            onSelected: onShadeSelected,
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            _QuantityStepper(value: quantity, onChanged: onQuantityChanged),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AddToCartButton(
                enabled: !product.isOutOfStock,
                label: product.isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                onPressed: () {
                  if (product.isOutOfStock) return;
                  cart.addProduct(
                    product,
                    variant: _selectedVariant(product),
                    quantity: quantity,
                  );
                  AddToCartFly.show(
                    context,
                    imageUrl: product.images.isNotEmpty ? product.images.first : '',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => wishlist.toggle(product.id),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: FutureBuilder<bool>(
                  future: wishlist.contains(product.id),
                  builder: (context, snapshot) {
                    final inWishlist = snapshot.data ?? false;
                    return WishlistHeart(
                      isSelected: inWishlist,
                      size: 22,
                      onPressed: () => wishlist.toggle(product.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Description', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description, style: const TextStyle(height: 1.5)),
        if (product.specifications.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Specifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...product.specifications.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(e.key,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _ReviewsSection(
          product: product,
          reviewsFuture: reviewsFuture,
          eligibilityFuture: eligibilityFuture,
          onWriteReview: onWriteReview,
        ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.product, required this.reviewsFuture});

  final Product product;
  final Future<List<Review>> reviewsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <Review>[];
        final rating = reviews.isEmpty ? product.rating : _average(reviews);
        final count = reviews.isEmpty ? product.reviewCount : reviews.length;
        return Row(
          children: [
            const Icon(Icons.star, color: QueensTouchColors.gold, size: 20),
            const SizedBox(width: 4),
            Text(rating.toStringAsFixed(1)),
            const SizedBox(width: 4),
            Text('($count reviews)',
                style: TextStyle(color: QueensTouchColors.textMuted)),
            const Spacer(),
            Text('${product.soldCount} sold',
                style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 13)),
          ],
        );
      },
    );
  }

  static double _average(List<Review> reviews) =>
      reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
}

/// Renders the gallery destination Hero on the first frame, before the
/// product loads, so the catalog-to-detail hero flight has a destination.
class _GalleryHeroShell extends StatelessWidget {
  const _GalleryHeroShell({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Hero(
        tag: 'product-image-$productId',
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: QueensTouchColors.blushLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: QueensTouchColors.plumLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;
    if (images.isEmpty) {
      return Hero(
        tag: 'product-image-${widget.product.id}',
        child: _imageContainer(
          const Center(
            child: Icon(Icons.checkroom, size: 80, color: QueensTouchColors.plumLight),
          ),
        ),
      );
    }
    return Column(
      children: [
        Hero(
          tag: 'product-image-${widget.product.id}',
          child: _imageContainer(
            Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => ProductImageReveal(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    presentation: presentationFor(
                      categorySlug: widget.product.categorySlug,
                      categoryId: widget.product.categoryId,
                    ),
                    semanticLabel: widget.product.name,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1}/${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? QueensTouchColors.plum : QueensTouchColors.blush,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _imageContainer(Widget child) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: QueensTouchColors.blushLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: selected == option,
                  onSelected: (_) => onSelect(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8DED7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          AnimatedSwitcher(
            duration: QtMotion.fast,
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.product,
    required this.reviewsFuture,
    required this.eligibilityFuture,
    required this.onWriteReview,
  });

  final Product product;
  final Future<List<Review>> reviewsFuture;
  final Future<ReviewEligibility> eligibilityFuture;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FutureBuilder<ReviewEligibility>(
          future: eligibilityFuture,
          builder: (context, snapshot) {
            final eligibility = snapshot.data;
            if (eligibility == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eligibility.canReview) ...[
                  OutlinedButton.icon(
                    onPressed: onWriteReview,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Write a Review'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!eligibility.canReview &&
                    eligibility.review != null) ...[
                  _OwnReviewStatus(review: eligibility.review!),
                  const SizedBox(height: 12),
                ],
                if (!eligibility.purchased)
                  Text(
                    'Verified buyers can write a review after their order is delivered.',
                    style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        FutureBuilder<List<Review>>(
          future: reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Could not load reviews.',
                  style: const TextStyle(color: QueensTouchColors.textMuted),
                ),
              );
            }
            final reviews = snapshot.data ?? const <Review>[];
            if (reviews.isEmpty) {
              return const EmptyState(
                icon: Icons.rate_review_outlined,
                title: 'No reviews yet',
                message: 'Be the first to review this product after your purchase.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final review in reviews) ...[
                  _ReviewTile(review: review),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OwnReviewStatus extends StatelessWidget {
  const _OwnReviewStatus({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch ((review.isApproved, review.isRejected)) {
      (true, _) => (QueensTouchColors.success, Icons.check_circle_outline),
      (_, true) => (QueensTouchColors.danger, Icons.cancel_outlined),
      _ => (QueensTouchColors.warning, Icons.hourglass_top),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Your review: ${review.statusLabel}',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QueensTouchColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QueensTouchColors.surfaceBorder),
      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: QueensTouchColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: QueensTouchColors.success),
                      SizedBox(width: 2),
                      Text('Verified', style: TextStyle(fontSize: 10, color: QueensTouchColors.success)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: QueensTouchColors.gold,
                ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}