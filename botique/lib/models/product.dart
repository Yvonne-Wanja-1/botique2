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

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final quantity = json['stockQty'] ?? json['quantity'];
    return ProductVariant(
      id: json['id'] as String,
      size: json['size'] as String?,
      color: json['color'] as String?,
      shade: json['shade'] as String?,
      quantity: quantity is num ? quantity.toInt() : 0,
      sku: json['sku'] as String?,
    );
  }

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

  factory Product.fromJson(Map<String, dynamic> json) {
    final basePrice = _asDouble(json['basePrice'] ?? json['price']);
    final discountPrice = _asNullableDouble(json['discountPrice']);
    final status = switch (json['status'] as String?) {
      'inactive' => ProductStatus.inactive,
      'out_of_stock' => ProductStatus.outOfStock,
      'discontinued' => ProductStatus.discontinued,
      _ => ProductStatus.active,
    };
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: basePrice,
      discountPrice: discountPrice,
      categoryId: json['categoryId'] as String? ?? '',
      brandId: json['brandId'] as String? ?? '',
      images: (json['images'] as List?)?.cast<String>() ?? const [],
      variants: (json['variants'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProductVariant.fromJson)
          .toList() ??
          const [],
      specifications: (json['specifications'] as Map?)?.cast<String, String>() ?? const {},
      stockThreshold: _asInt(json['stockThreshold'] ?? 5),
      status: status,
      labels: _labelsFromJson(json),
      rating: _asDouble(json['rating'] ?? 0),
      reviewCount: _asInt(json['reviewCount'] ?? 0),
      soldCount: _asInt(json['soldCount'] ?? 0),
      viewCount: _asInt(json['viewCount'] ?? 0),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

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

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Set<ProductLabel> _labelsFromJson(Map<String, dynamic> json) {
  final labels = <ProductLabel>{};
  if (json['isFeatured'] == true) labels.add(ProductLabel.featured);
  if (json['isNewArrival'] == true) labels.add(ProductLabel.newArrival);
  if (json['isBestSeller'] == true) labels.add(ProductLabel.bestSeller);
  if (json['isTrending'] == true) labels.add(ProductLabel.trending);
  if (json['discountPrice'] != null) labels.add(ProductLabel.onSale);
  return labels;
}
