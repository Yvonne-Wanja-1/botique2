import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/product.dart';

class MockCatalogData {
  MockCatalogData._();

  static final List<Brand> brands = [
    const Brand(id: 'b1', name: 'Velvet Rose'),
    const Brand(id: 'b2', name: 'Crown & Co'),
    const Brand(id: 'b3', name: 'Luxé Beaute'),
    const Brand(id: 'b4', name: 'Maison Élégance'),
    const Brand(id: 'b5', name: 'Silk Garden'),
    const Brand(id: 'b6', name: 'Royal Glow'),
  ];

  static final List<Category> categories = [
    // Clothing
    const Category(id: 'clothing', name: 'Clothing', description: 'Elegant womenswear for every occasion'),
    const Category(id: 'clothing-dresses', name: 'Dresses', parentId: 'clothing'),
    const Category(id: 'clothing-tops', name: 'Tops', parentId: 'clothing'),
    const Category(id: 'clothing-trousers', name: 'Trousers', parentId: 'clothing'),
    const Category(id: 'clothing-jeans', name: 'Jeans', parentId: 'clothing'),
    const Category(id: 'clothing-skirts', name: 'Skirts', parentId: 'clothing'),
    const Category(id: 'clothing-jackets', name: 'Jackets', parentId: 'clothing'),
    const Category(id: 'clothing-sweaters', name: 'Sweaters', parentId: 'clothing'),
    const Category(id: 'clothing-jumpsuits', name: 'Jumpsuits', parentId: 'clothing'),
    const Category(id: 'clothing-activewear', name: 'Activewear', parentId: 'clothing'),
    const Category(id: 'clothing-loungewear', name: 'Loungewear', parentId: 'clothing'),
    // Cosmetics & Beauty
    const Category(id: 'beauty', name: 'Cosmetics & Beauty', description: 'Makeup, skincare and self-care essentials'),
    const Category(id: 'beauty-makeup', name: 'Makeup', parentId: 'beauty'),
    const Category(id: 'beauty-lip', name: 'Lip Products', parentId: 'beauty'),
    const Category(id: 'beauty-foundation', name: 'Foundation', parentId: 'beauty'),
    const Category(id: 'beauty-concealer', name: 'Concealer', parentId: 'beauty'),
    const Category(id: 'beauty-blush', name: 'Blush', parentId: 'beauty'),
    const Category(id: 'beauty-eyeshadow', name: 'Eyeshadow', parentId: 'beauty'),
    const Category(id: 'beauty-mascara', name: 'Mascara', parentId: 'beauty'),
    const Category(id: 'beauty-skincare', name: 'Skincare', parentId: 'beauty'),
    const Category(id: 'beauty-body', name: 'Body Care', parentId: 'beauty'),
    const Category(id: 'beauty-hair', name: 'Hair Products', parentId: 'beauty'),
    const Category(id: 'beauty-accessories', name: 'Beauty Accessories', parentId: 'beauty'),
  ];

  static List<ProductVariant> sizes(List<String> sizes, {int perVariant = 8}) {
    return [
      for (final size in sizes)
        ProductVariant(
          id: 'v-${size.hashCode}',
          size: size,
          quantity: perVariant,
        ),
    ];
  }

  static List<ProductVariant> shades(List<String> shades, {int perVariant = 15}) {
    return [
      for (final shade in shades)
        ProductVariant(id: 'v-${shade.hashCode}', shade: shade, quantity: perVariant),
    ];
  }

  static List<ProductVariant> colorsOf(List<String> colors, {int perVariant = 8}) {
    return [
      for (final color in colors)
        ProductVariant(id: 'v-${color.hashCode}', color: color, quantity: perVariant),
    ];
  }

  static final List<Product> products = [
    Product(
      id: 'p1',
      name: 'Rosé Midi Wrap Dress',
      description:
          'A timeless midi wrap dress in soft rosé, cut to flatter the waist and flow beautifully. Perfect for daytime elegance or evening cocktails.',
      price: 89.99,
      discountPrice: 69.99,
      categoryId: 'clothing-dresses',
      brandId: 'b1',
      images: const [],
      variants: sizes(['XS', 'S', 'M', 'L', 'XL']),
      specifications: const {'Fabric': 'Viscose blend', 'Fit': 'True to size', 'Care': 'Hand wash cold'},
      stockThreshold: 6,
      labels: {ProductLabel.featured, ProductLabel.bestSeller, ProductLabel.onSale},
      rating: 4.8,
      reviewCount: 132,
      soldCount: 540,
      viewCount: 3200,
      createdAt: DateTime(2026, 8, 2),
    ),
    Product(
      id: 'p2',
      name: 'Velvet Blush Blazer',
      description:
          'A soft velvet blazer in blush pink that adds instant polish. Structured shoulders with a relaxed drape.',
      price: 129.99,
      categoryId: 'clothing-jackets',
      brandId: 'b2',
      images: const [],
      variants: sizes(['S', 'M', 'L', 'XL']),
      specifications: const {'Fabric': 'Velvet', 'Fit': 'Relaxed', 'Care': 'Dry clean only'},
      stockThreshold: 5,
      labels: {ProductLabel.featured, ProductLabel.trending},
      rating: 4.6,
      reviewCount: 64,
      soldCount: 210,
      viewCount: 1850,
      createdAt: DateTime(2026, 7, 28),
    ),
    Product(
      id: 'p3',
      name: 'Signature Silk Scarf',
      description:
          'An iconic silk scarf with the Queens\' Touch signature pattern. Wear it at the neck, in your hair, or on your favourite bag.',
      price: 49.99,
      discountPrice: 39.99,
      categoryId: 'beauty-accessories',
      brandId: 'b4',
      images: const [],
      variants: colorsOf(['Blush', 'Plum', 'Gold', 'Ivory']),
      specifications: const {'Material': '100% silk twill', 'Size': '90 x 90 cm'},
      stockThreshold: 8,
      labels: {ProductLabel.bestSeller, ProductLabel.onSale},
      rating: 4.9,
      reviewCount: 218,
      soldCount: 980,
      viewCount: 4100,
      createdAt: DateTime(2026, 7, 20),
    ),
    Product(
      id: 'p4',
      name: 'Velvet Matte Lipstick - Queen',
      description:
          'A creamy matte lipstick with full coverage and a velvet finish. Long-wearing formula infused with shea butter.',
      price: 24.99,
      discountPrice: 19.99,
      categoryId: 'beauty-lip',
      brandId: 'b3',
      images: const [],
      variants: shades(['Queen Red', 'Royal Nude', 'Plum Kiss', 'Rose Petal']),
      specifications: const {'Finish': 'Matte', 'Volume': '3.5 g', 'Cruelty Free': 'Yes'},
      stockThreshold: 20,
      labels: {ProductLabel.bestSeller, ProductLabel.trending, ProductLabel.onSale},
      rating: 4.7,
      reviewCount: 342,
      soldCount: 1500,
      viewCount: 5200,
      createdAt: DateTime(2026, 7, 15),
    ),
    Product(
      id: 'p5',
      name: 'Silk Garden Maxi Dress',
      description:
          'A flowing maxi dress in a botanical print, cut on the bias for an effortless, statuesque silhouette.',
      price: 109.99,
      categoryId: 'clothing-dresses',
      brandId: 'b5',
      images: const [],
      variants: sizes(['XS', 'S', 'M', 'L']),
      specifications: const {'Fabric': 'Silk blend', 'Fit': 'Flowy', 'Care': 'Dry clean'},
      stockThreshold: 5,
      labels: {ProductLabel.newArrival, ProductLabel.featured},
      rating: 4.5,
      reviewCount: 28,
      soldCount: 90,
      viewCount: 1200,
      createdAt: DateTime(2026, 8, 8),
    ),
    Product(
      id: 'p6',
      name: 'High-Rise Wide-Leg Trousers',
      description:
          'Crisp tailoring meets comfort in these high-rise wide-leg trousers. A wardrobe staple for the modern queen.',
      price: 74.99,
      categoryId: 'clothing-trousers',
      brandId: 'b2',
      images: const [],
      variants: sizes(['XS', 'S', 'M', 'L', 'XL']),
      specifications: const {'Fabric': 'Twill', 'Fit': 'Wide leg', 'Care': 'Machine wash'},
      stockThreshold: 6,
      labels: {ProductLabel.trending},
      rating: 4.4,
      reviewCount: 85,
      soldCount: 320,
      viewCount: 1600,
      createdAt: DateTime(2026, 6, 30),
    ),
    Product(
      id: 'p7',
      name: 'Luminous Foundation - Medium Tan',
      description:
          'A buildable, luminous foundation that evens tone with a natural glow. Available in 12 inclusive shades.',
      price: 39.99,
      categoryId: 'beauty-foundation',
      brandId: 'b3',
      images: const [],
      variants: shades(['Fair', 'Light', 'Medium Tan', 'Deep', 'Rich Brown']),
      specifications: const {'Coverage': 'Buildable', 'Finish': 'Luminous', 'Volume': '30 ml'},
      stockThreshold: 15,
      labels: {ProductLabel.featured, ProductLabel.bestSeller},
      rating: 4.6,
      reviewCount: 189,
      soldCount: 760,
      viewCount: 2800,
      createdAt: DateTime(2026, 6, 25),
    ),
    Product(
      id: 'p8',
      name: 'Hydra Glow Serum',
      description:
          'A weightless serum that drenches skin in hydration and leaves a lit-from-within glow. Hyaluronic acid + vitamin C.',
      price: 34.99,
      categoryId: 'beauty-skincare',
      brandId: 'b6',
      images: const [],
      variants: sizes(['30 ml', '50 ml']),
      specifications: const {'Skin type': 'All', 'Key actives': 'Hyaluronic acid, Vitamin C'},
      stockThreshold: 12,
      labels: {ProductLabel.trending, ProductLabel.newArrival},
      rating: 4.9,
      reviewCount: 156,
      soldCount: 620,
      viewCount: 3400,
      createdAt: DateTime(2026, 8, 5),
    ),
    Product(
      id: 'p9',
      name: 'Corset-Style Jumpsuit',
      description:
          'A sculpted corset jumpsuit with wide legs and a dramatic flared silhouette. Evening glamour made easy.',
      price: 99.99,
      discountPrice: 79.99,
      categoryId: 'clothing-jumpsuits',
      brandId: 'b1',
      images: const [],
      variants: sizes(['S', 'M', 'L']),
      specifications: const {'Fabric': 'Crepe', 'Fit': 'Sculpted', 'Care': 'Dry clean'},
      stockThreshold: 5,
      labels: {ProductLabel.onSale, ProductLabel.trending},
      rating: 4.3,
      reviewCount: 47,
      soldCount: 175,
      viewCount: 900,
      createdAt: DateTime(2026, 5, 18),
    ),
    Product(
      id: 'p10',
      name: 'Plush Lounge Set',
      description:
          'A buttery-soft two-piece lounge set in a cloud-feel knit. Sunday comfort with queen energy.',
      price: 59.99,
      categoryId: 'clothing-loungewear',
      brandId: 'b5',
      images: const [],
      variants: sizes(['S', 'M', 'L', 'XL']),
      specifications: const {'Fabric': 'Modal blend', 'Fit': 'Relaxed', 'Care': 'Machine wash'},
      stockThreshold: 8,
      labels: {ProductLabel.newArrival},
      rating: 4.7,
      reviewCount: 39,
      soldCount: 140,
      viewCount: 1100,
      createdAt: DateTime(2026, 8, 10),
    ),
    Product(
      id: 'p11',
      name: 'Scalp Detox Hair Mask',
      description:
          'A weekly treatment that clarifies the scalp and strengthens strands with natural botanical extracts.',
      price: 29.99,
      categoryId: 'beauty-hair',
      brandId: 'b6',
      images: const [],
      variants: sizes(['200 ml']),
      specifications: const {'Use': 'Weekly', 'Key actives': 'Rosemary, Aloe'},
      stockThreshold: 10,
      labels: {ProductLabel.bestSeller},
      rating: 4.5,
      reviewCount: 71,
      soldCount: 290,
      viewCount: 1300,
      createdAt: DateTime(2026, 6, 12),
    ),
    Product(
      id: 'p12',
      name: 'Crystal Statement Earrings',
      description:
          'Hand-finished crystal earrings that catch the light with every move. The finishing touch for any look.',
      price: 44.99,
      discountPrice: 34.99,
      categoryId: 'beauty-accessories',
      brandId: 'b4',
      images: const [],
      variants: colorsOf(['Gold', 'Silver', 'Rose Gold']),
      specifications: const {'Material': 'Crystal, gold-plated', 'Type': 'Drop earrings'},
      stockThreshold: 6,
      labels: {ProductLabel.onSale, ProductLabel.trending},
      rating: 4.8,
      reviewCount: 92,
      soldCount: 430,
      viewCount: 2400,
      createdAt: DateTime(2026, 7, 5),
    ),
    Product(
      id: 'p13',
      name: 'Everyday Straight-Leg Jeans',
      description:
          'The perfect pair of straight-leg jeans in a rich indigo wash. Comfortable stretch with a flattering rise.',
      price: 64.99,
      categoryId: 'clothing-jeans',
      brandId: 'b2',
      images: const [],
      variants: sizes(['24', '26', '28', '30', '32']),
      specifications: const {'Fabric': 'Denim with stretch', 'Rise': 'Mid', 'Care': 'Machine wash'},
      stockThreshold: 6,
      labels: {ProductLabel.bestSeller},
      rating: 4.5,
      reviewCount: 110,
      soldCount: 460,
      viewCount: 2000,
      createdAt: DateTime(2026, 6, 8),
    ),
    Product(
      id: 'p14',
      name: 'Plush Velvet Mascara',
      description:
          'Volumizing mascara with a plush brush that lifts and separates for dramatic, feathery lashes. Smudge-proof.',
      price: 21.99,
      categoryId: 'beauty-mascara',
      brandId: 'b3',
      images: const [],
      variants: shades(['Black', 'Brown Black']),
      specifications: const {'Finish': 'Volumizing', 'Waterproof': 'No', 'Volume': '10 ml'},
      stockThreshold: 18,
      labels: {ProductLabel.featured},
      rating: 4.4,
      reviewCount: 58,
      soldCount: 240,
      viewCount: 950,
      createdAt: DateTime(2026, 7, 22),
    ),
    Product(
      id: 'p15',
      name: 'Chiffon Pleated Skirt',
      description:
          'A featherlight pleated chiffon skirt that moves with you. Tiers of soft shimmer, perfect for evenings.',
      price: 54.99,
      categoryId: 'clothing-skirts',
      brandId: 'b5',
      images: const [],
      variants: sizes(['XS', 'S', 'M', 'L']),
      specifications: const {'Fabric': 'Chiffon', 'Fit': 'A-line', 'Care': 'Hand wash'},
      stockThreshold: 7,
      labels: {ProductLabel.newArrival},
      rating: 4.6,
      reviewCount: 33,
      soldCount: 120,
      viewCount: 780,
      createdAt: DateTime(2026, 8, 6),
    ),
    Product(
      id: 'p16',
      name: 'Bronze Glow Blush Palette',
      description:
          'A curated palette of three warm blush and bronze shades for a sun-kissed, healthy glow.',
      price: 27.99,
      categoryId: 'beauty-blush',
      brandId: 'b3',
      images: const [],
      variants: shades(['Warm Sunset', 'Rosy Dawn']),
      specifications: const {'Shades': '3', 'Finish': 'Satin', 'Cruelty Free': 'Yes'},
      stockThreshold: 14,
      labels: {ProductLabel.trending},
      rating: 4.7,
      reviewCount: 66,
      soldCount: 260,
      viewCount: 1400,
      createdAt: DateTime(2026, 7, 30),
    ),
  ];

  static List<Product> byCategory(String categoryId) {
    final direct = products.where((p) => p.categoryId == categoryId).toList();
    final parent = categories.firstWhere((c) => c.id == categoryId, orElse: () => categories.first);
    if (parent.parentId != null) return direct;
    final subIds = categories.where((c) => c.parentId == categoryId).map((c) => c.id).toSet();
    final fromSubs = products.where((p) => subIds.contains(p.categoryId)).toList();
    return [...direct, ...fromSubs];
  }
}