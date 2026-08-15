enum ProductStatus { active, inactive, outOfStock, discontinued }

enum ProductLabel {
  featured,
  newArrival,
  bestSeller,
  trending,
  onSale;

  String get label => switch (this) {
        ProductLabel.featured => 'Featured',
        ProductLabel.newArrival => 'New Arrival',
        ProductLabel.bestSeller => 'Best Seller',
        ProductLabel.trending => 'Trending',
        ProductLabel.onSale => 'On Sale',
      };
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    this.size,
    this.color,
    this.shade,
    required this.quantity,
    this.sku,
  });

  final String id;
  final String? size;
  final String? color;
  final String? shade;
  final int quantity;
  final String? sku;

  String get label => [
        if (size != null) 'Size: $size',
        if (color != null) 'Color: $color',
        if (shade != null) 'Shade: $shade',
      ].join(' · ');
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.brandId,
    required this.images,
    this.discountPrice,
    this.variants = const [],
    this.specifications = const {},
    this.stockThreshold = 5,
    this.status = ProductStatus.active,
    this.labels = const {},
    this.rating = 0,
    this.reviewCount = 0,
    this.soldCount = 0,
    this.viewCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String categoryId;
  final String brandId;
  final List<String> images;
  final List<ProductVariant> variants;
  final Map<String, String> specifications;
  final int stockThreshold;
  final ProductStatus status;
  final Set<ProductLabel> labels;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final int viewCount;
  final DateTime? createdAt;

  double get effectivePrice => discountPrice ?? price;

  int get totalStock => variants.fold(0, (sum, v) => sum + v.quantity);

  bool get isLowStock => totalStock > 0 && totalStock <= stockThreshold;

  bool get isOutOfStock => totalStock == 0 || status == ProductStatus.outOfStock;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  double get discountPercent =>
      hasDiscount ? ((price - discountPrice!) / price * 100).roundToDouble() : 0;

  bool hasLabel(ProductLabel label) => labels.contains(label);
}
