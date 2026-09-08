import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/fashion_beauty_reveal.dart';
import '../../core/animations/product_image_reveal.dart';
import '../../core/animations/product_presentation.dart';
import '../../core/animations/stagger_reveal.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/product_card.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../services/catalog_service.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scroll = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollController.dispose();
    _scroll.dispose();
    super.dispose();
  }

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

    final fashion = catalog.featured
        .where((p) =>
            presentationFor(categorySlug: p.categorySlug, categoryId: p.categoryId) ==
            ProductPresentation.fashion)
        .take(8)
        .toList();
    final beauty = catalog.featured
        .where((p) =>
            presentationFor(categorySlug: p.categorySlug, categoryId: p.categoryId) !=
            ProductPresentation.fashion)
        .take(8)
        .toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _scroll.value = notification.metrics.pixels;
        return false;
      },
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          _CampaignHero(scrollOffset: _scroll),
          _NewCollectionSection(products: catalog.newArrivals),
          const _SectionHeader(title: 'Shop by Category'),
          _CategoryChips(categories: catalog.rootCategories),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Featured', subtitle: 'Handpicked for you'),
          _ProductRow(products: catalog.featured),
          const _SectionHeader(title: 'Fashion', subtitle: 'Curated womenswear'),
          _CuratedRow(products: fashion),
          const _SectionHeader(title: 'Beauty', subtitle: 'Makeup, skincare and glow'),
          _CuratedRow(products: beauty),
          const _SectionHeader(title: 'Best Sellers', subtitle: 'Loved by our queens'),
          _ProductRow(products: catalog.bestSellers),
          const _OfferBanner(),
          const _SectionHeader(title: 'Trending Now'),
          _ProductRow(products: catalog.trending),
          const _SectionHeader(title: 'Recommended for You'),
          _ProductRow(products: catalog.recommended),
          const _NewsletterSection(),
          const _FooterSection(),
        ],
      ),
    );
  }
}

class _CampaignHero extends StatelessWidget {
  const _CampaignHero({required this.scrollOffset});

  final ValueNotifier<double> scrollOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final parallax = (offset.clamp(0.0, 200.0) * 0.25).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FashionReveal(
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [QueensTouchColors.plumDark, QueensTouchColors.plum],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -60,
                      bottom: -40,
                      child: Transform.translate(
                        offset: Offset(0, parallax),
                        child: Icon(
                          Icons.diamond,
                          size: 250,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: ClipOval(
                          child: Opacity(
                            opacity: 0.9,
                            child: const Image(
                              image: AssetImage('lib/assets/images/icon.jpeg'),
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaggerReveal(
                            index: 0,
                            child: Text(
                              'THE NEW COLLECTION',
                              style: TextStyle(
                                color: QueensTouchColors.goldLight,
                                fontSize: 12,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          StaggerReveal(
                            index: 1,
                            child: Text(
                              'Elegance is in\nher every step',
                              style: QueensTouchTheme.brandSerif(
                                fontSize: 34,
                                weight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          StaggerReveal(
                            index: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CatalogScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: QueensTouchColors.plumDark,
                              ),
                              child: const Text('Shop Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NewCollectionSection extends StatelessWidget {
  const _NewCollectionSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final hero = products.isNotEmpty ? products.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggerReveal(
            index: 0,
            child: Text(
              'NEW COLLECTION',
              style: QueensTouchTheme.brandSerif(fontSize: 28, weight: FontWeight.w700),
            ),
          ),
          StaggerReveal(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Fresh from the atelier — discover what is new this season.',
                style: const TextStyle(color: QueensTouchColors.textMuted),
              ),
            ),
          ),
          if (hero != null) ...[
            const SizedBox(height: 14),
            StaggerReveal(
              index: 2,
              child: _CollectionBanner(product: hero),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(
      categorySlug: product.categorySlug,
      categoryId: product.categoryId,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageReveal(
              imageUrl: product.images.isNotEmpty ? product.images.first : '',
              presentation: presentation,
              cacheWidth: 800,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QueensTouchTheme.brandSerif(
                        fontSize: 20,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatKsh(product.effectivePrice),
                    style: const TextStyle(
                      color: QueensTouchColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            style: QueensTouchTheme.brandSerif(fontSize: 20, weight: FontWeight.w700),
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
        separatorBuilder: (_, _) => const SizedBox(width: 12),
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
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: Responsive.isMobile(context) ? 150 : 200,
            child: StaggerReveal(
              index: index,
              child: ProductCard(product: product),
            ),
          );
        },
      ),
    );
  }
}

class _CuratedRow extends StatelessWidget {
  const _CuratedRow({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: Responsive.isMobile(context) ? 150 : 200,
            child: StaggerReveal(
              index: index,
              child: ProductCard(product: product),
            ),
          );
        },
      ),
    );
  }
}

class _OfferBanner extends StatefulWidget {
  const _OfferBanner();

  @override
  State<_OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<_OfferBanner> {
  late final Future<List<Promotion>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PromotionRepository>().getActive();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Promotion>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final promos = snapshot.data;
        if (promos == null || promos.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [QueensTouchColors.gold, QueensTouchColors.goldLight],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTIVE PROMOTIONS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: QueensTouchColors.plumDark,
                ),
              ),
              const SizedBox(height: 12),
              ...promos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: p.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Promo code "${p.code}" copied!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: QueensTouchColors.success,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: QueensTouchColors.plumDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: Colors.white70),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: QueensTouchColors.plumDark,
                              ),
                            ),
                            if (p.description != null && p.description!.isNotEmpty)
                              Text(
                                p.description!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: QueensTouchColors.plumDark.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        p.isPercentage ? '${p.value.round()}% OFF' : '${formatKsh(p.value)} OFF',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: QueensTouchColors.plumDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
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
            'QUEENS\' TOUCH BEAUTY SHOP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
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
          const _FooterRow(icon: Icons.phone_outlined, text: '0714 184 601'),
          const SizedBox(height: 6),
          const _FooterRow(icon: Icons.phone_outlined, text: '0725 865 727'),
          const SizedBox(height: 6),
          const _FooterRow(icon: Icons.email_outlined, text: 'queenstouchbeauty333@gmail.com'),
          const SizedBox(height: 20),
          const Text(
            'Pay with M-Pesa',
            style: TextStyle(
              color: QueensTouchColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const _FooterRow(icon: Icons.payment, text: 'Paybill: 222111  |  Account: 65727'),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://www.tiktok.com/@yvonne0963?_r=1&_t=ZS-99ETqt9LR0K');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tiktok, color: QueensTouchColors.goldLight, size: 20),
                SizedBox(width: 8),
                Text(
                  '@yvonne0963',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 Queens\' Touch Beauty Shop. All rights reserved.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: QueensTouchColors.goldLight, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}