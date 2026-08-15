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

  void seedReviews(Review review) => _reviews.add(review);
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
