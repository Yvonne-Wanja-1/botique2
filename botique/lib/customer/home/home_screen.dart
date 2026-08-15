import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/category.dart';
import '../../services/catalog_service.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/categories_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();

    if (catalog.loading) {
      return const LoadingView(message: 'Curating your boutique...');
    }
    if (catalog.error != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not load the boutique',
        message: catalog.error,
        action: OutlinedButton.icon(
          onPressed: () => context.read<CatalogService>().loadHome(),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _HeroBanner(),
        const _SectionHeader(title: 'Shop by Category'),
        _CategoryChips(categories: catalog.rootCategories),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Featured', subtitle: 'Handpicked for you'),
        _ProductRow(products: catalog.featured),
        const _SectionHeader(title: 'New Arrivals', subtitle: 'Fresh from the atelier'),
        _ProductRow(products: catalog.newArrivals),
        const _OfferBanner(),
        const _SectionHeader(title: 'Best Sellers', subtitle: 'Loved by our queens'),
        _ProductRow(products: catalog.bestSellers),
        const _SectionHeader(title: 'Trending Now'),
        _ProductRow(products: catalog.trending),
        const _SectionHeader(title: 'Recommended for You'),
        _ProductRow(products: catalog.recommended),
        const _NewsletterSection(),
        const _FooterSection(),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QueensTouchColors.plumDark, QueensTouchColors.plum],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.diamond,
              size: 160,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'THE NEW COLLECTION',
                  style: TextStyle(
                    color: QueensTouchColors.goldLight,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elegance is in\nher every step',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: QueensTouchColors.plumDark,
                  ),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CategoriesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 88,
              decoration: BoxDecoration(
                color: QueensTouchColors.blushLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.id == 'clothing'
                        ? Icons.checkroom
                        : Icons.face_retouching_natural,
                    color: QueensTouchColors.plum,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.products});

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: Responsive.isMobile(context) ? 150 : 200,
            child: ProductCard(product: product),
          );
        },
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [QueensTouchColors.gold, QueensTouchColors.goldLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPECIAL OFFER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: QueensTouchColors.plumDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Up to 20% off\nsignature pieces',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: QueensTouchColors.plumDark,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: QueensTouchColors.plumDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Shop Sale'),
          ),
        ],
      ),
    );
  }
}

class _NewsletterSection extends StatelessWidget {
  const _NewsletterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QueensTouchColors.blushLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Join the Inner Circle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Exclusive offers, new arrivals and beauty tips, straight to your inbox.',
            textAlign: TextAlign.center,
            style: TextStyle(color: QueensTouchColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Your email address',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: QueensTouchColors.plum),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: QueensTouchColors.plumDark,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        children: [
          const Text(
            'QUEENS\' TOUCH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ELEGANCE FOR EVERY QUEEN',
            style: TextStyle(
              color: QueensTouchColors.goldLight,
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.location_on_outlined, color: QueensTouchColors.goldLight, size: 16),
              SizedBox(width: 6),
              Text('Lagos, Nigeria', style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(width: 20),
              Icon(Icons.phone_outlined, color: QueensTouchColors.goldLight, size: 16),
              SizedBox(width: 6),
              Text('+234 800 000 0000', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'hello@queenstouch.com',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: QueensTouchColors.goldLight),
              SizedBox(width: 20),
              Icon(Icons.thumb_up_alt_outlined, color: QueensTouchColors.goldLight),
              SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline, color: QueensTouchColors.goldLight),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 Queens\' Touch. All rights reserved.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}