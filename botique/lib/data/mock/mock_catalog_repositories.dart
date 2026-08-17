import 'dart:async';

import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../mock/mock_catalog_data.dart';
import '../repositories/catalog_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products = List.of(MockCatalogData.products);
  final List<Review> _reviews = [];
  final Map<String, List<ProductImage>> _imageRecords = {};
  int _seq = 0;

  String _nextId() => 'mock-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  @override
  Future<List<Product>> getFeatured() async {
    return _products.where((p) => p.hasLabel(ProductLabel.featured)).toList();
  }

  @override
  Future<List<Product>> getNewArrivals() async {
    final sorted = List.of(_products)..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return sorted.where((p) => p.hasLabel(ProductLabel.newArrival) || sorted.indexOf(p) < 6).take(6).toList();
  }

  @override
  Future<List<Product>> getBestSellers() async {
    final sorted = List.of(_products)..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return sorted.take(8).toList();
  }

  @override
  Future<List<Product>> getTrending() async {
    return _products.where((p) => p.hasLabel(ProductLabel.trending)).toList();
  }

  @override
  Future<List<Product>> getRecommended({String? customerId}) async {
    final popular = List.of(_products)
      ..sort((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));
    return popular.take(6).toList();
  }

  @override
  Future<CatalogResult> search(
    ProductFilter filter,
    ProductSort sort, {
    int page = 1,
    int pageSize = 20,
  }) async {
    var results = _products.where((p) {
      if (p.status == ProductStatus.inactive || p.status == ProductStatus.discontinued) return false;
      if (filter.categoryId != null &&
          !MockCatalogData.byCategory(filter.categoryId!).any((c) => c.id == p.id)) {
        return false;
      }
      if (filter.brandId != null && p.brandId != filter.brandId) return false;
      if (filter.minPrice != null && p.effectivePrice < filter.minPrice!) return false;
      if (filter.maxPrice != null && p.effectivePrice > filter.maxPrice!) return false;
      if (filter.sizes.isNotEmpty &&
          !p.variants.any((v) => v.size != null && filter.sizes.contains(v.size))) {
        return false;
      }
      if (filter.colors.isNotEmpty &&
          !p.variants.any((v) => v.color != null && filter.colors.contains(v.color))) {
        return false;
      }
      if (filter.availability == true && p.isOutOfStock) return false;
      if (filter.availability == false && !p.isOutOfStock) return false;
      if (filter.minRating != null && p.rating < filter.minRating!) return false;
      if (filter.onSaleOnly && !p.hasDiscount) return false;
      if (filter.search != null && filter.search!.isNotEmpty) {
        final q = filter.search!.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.newest:
        results.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      case ProductSort.priceLowHigh:
        results.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      case ProductSort.priceHighLow:
        results.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
      case ProductSort.bestSelling:
        results.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      case ProductSort.bestRated:
        results.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSort.discount:
        results.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }

    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, results.length);
    final pageItems = start >= results.length ? <Product>[] : results.sublist(start, end);
    return CatalogResult(products: pageItems, total: results.length);
  }

  @override
  Future<Product?> getById(String id) async {
    return _products.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    return _reviews.where((r) => r.productId == productId).toList();
  }

  @override
  Future<List<Product>> getAll({String? search}) async {
    final q = search?.toLowerCase() ?? '';
    final all = q.isEmpty ? _products : _products.where((p) => p.name.toLowerCase().contains(q)).toList();
    return List.of(all);
  }

  @override
  Future<Product> create(ProductDraft draft) async {
    final product = _fromDraft(_nextId(), draft, null);
    _products.add(product);
    return product;
  }

  @override
  Future<Product> update(String id, ProductDraft draft) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index < 0) throw StateError('Product $id not found');
    final product = _fromDraft(id, draft, _products[index]);
    _products[index] = product;
    return product;
  }

  @override
  Future<void> deactivate(String id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final p = _products[index];
      _products[index] = _copyWith(p, status: ProductStatus.inactive);
    }
  }

  @override
  Future<List<ProductImage>> getImages(String productId) async {
    return List.of(_imageRecords[productId] ?? const []);
  }

  @override
  Future<List<ProductImage>> uploadImages(String productId, List<UploadImage> images) async {
    if (!_products.any((p) => p.id == productId)) {
      throw StateError('Product $productId not found');
    }
    final existing = _imageRecords[productId] ?? <ProductImage>[];
    var nextPosition = existing.isEmpty ? 0 : existing.map((i) => i.position).reduce((a, b) => a > b ? a : b) + 1;
    final created = <ProductImage>[];
    for (var i = 0; i < images.length; i++) {
      final image = ProductImage(
        id: _nextId(),
        url: '/images/mock-${images[i].filename}',
        position: nextPosition + i,
        isPrimary: nextPosition + i == 0,
      );
      existing.add(image);
      created.add(image);
    }
    _imageRecords[productId] = existing;
    return created;
  }

  @override
  Future<void> deleteImage(String productId, String imageId) async {
    final existing = _imageRecords[productId] ?? <ProductImage>[];
    _imageRecords[productId] = existing.where((i) => i.id != imageId).toList();
  }

  @override
  Future<ProductImage> setPrimaryImage(String productId, String imageId) async {
    final existing = _imageRecords[productId] ?? <ProductImage>[];
    ProductImage? target;
    _imageRecords[productId] = [
      for (final i in existing)
        if (i.id == imageId) ...[
          target = ProductImage(id: i.id, url: i.url, position: 0, isPrimary: true),
        ] else
          ProductImage(id: i.id, url: i.url, position: i.position, isPrimary: false),
    ];
    final updated = _imageRecords[productId]!;
    return target ?? updated.first;
  }

  Product _fromDraft(String id, ProductDraft draft, Product? existing) {
    return Product(
      id: id,
      name: draft.name,
      description: draft.description,
      price: draft.basePrice,
      discountPrice: draft.discountPrice,
      categoryId: draft.categoryId,
      brandId: draft.brandId,
      images: existing?.images ?? const [],
      variants: draft.variants
          .map((v) => ProductVariant(
                id: _nextId(),
                size: v.size,
                color: v.color,
                shade: v.shade,
                quantity: v.stockQty,
                sku: v.sku,
              ))
          .toList(),
      specifications: draft.specifications,
      stockThreshold: draft.stockThreshold,
      status: existing?.status ?? ProductStatus.active,
      labels: {
        if (draft.isFeatured) ProductLabel.featured,
        if (draft.isNewArrival) ProductLabel.newArrival,
        if (draft.isBestSeller) ProductLabel.bestSeller,
        if (draft.isTrending) ProductLabel.trending,
        if (draft.discountPrice != null) ProductLabel.onSale,
      },
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
  }

  Product _copyWith(Product p, {ProductStatus? status}) => Product(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        discountPrice: p.discountPrice,
        categoryId: p.categoryId,
        brandId: p.brandId,
        images: p.images,
        variants: p.variants,
        specifications: p.specifications,
        stockThreshold: p.stockThreshold,
        status: status ?? p.status,
        labels: p.labels,
        rating: p.rating,
        reviewCount: p.reviewCount,
        soldCount: p.soldCount,
        viewCount: p.viewCount,
        createdAt: p.createdAt,
      );

  void seedReviews(Review review) => _reviews.add(review);

  void seedProduct(Product product) => _products.add(product);
}

class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getRootCategories() async {
    return MockCatalogData.categories.where((c) => c.parentId == null).toList();
  }

  @override
  Future<List<Category>> getSubcategories(String parentId) async {
    return MockCatalogData.categories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    return MockCatalogData.categories.where((c) => c.id == id).firstOrNull;
  }
}

class MockBrandRepository implements BrandRepository {
  @override
  Future<List<Brand>> getAll() async {
    return MockCatalogData.brands;
  }

  @override
  Future<Brand?> getById(String id) async {
    return MockCatalogData.brands.where((b) => b.id == id).firstOrNull;
  }
}
