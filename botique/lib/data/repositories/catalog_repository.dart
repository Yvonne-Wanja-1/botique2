import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/brand.dart';
import '../../models/review.dart';

class CatalogResult {
  const CatalogResult({
    required this.products,
    required this.total,
  });

  final List<Product> products;
  final int total;
}

enum ProductSort {
  newest,
  priceLowHigh,
  priceHighLow,
  bestSelling,
  bestRated,
  discount;

  String get label => switch (this) {
        ProductSort.newest => 'Newest',
        ProductSort.priceLowHigh => 'Price: Low to High',
        ProductSort.priceHighLow => 'Price: High to Low',
        ProductSort.bestSelling => 'Best Selling',
        ProductSort.bestRated => 'Best Rated',
        ProductSort.discount => 'Discount',
      };
}

class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.sizes = const [],
    this.colors = const [],
    this.availability,
    this.minRating,
    this.onSaleOnly = false,
    this.search,
  });

  final String? categoryId;
  final String? brandId;
  final double? minPrice;
  final double? maxPrice;
  final List<String> sizes;
  final List<String> colors;
  final bool? availability;
  final double? minRating;
  final bool onSaleOnly;
  final String? search;

  bool get isEmpty =>
      categoryId == null &&
      brandId == null &&
      minPrice == null &&
      maxPrice == null &&
      sizes.isEmpty &&
      colors.isEmpty &&
      availability == null &&
      minRating == null &&
      !onSaleOnly &&
      search == null;

  ProductFilter copyWith({
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    List<String>? sizes,
    List<String>? colors,
    bool? availability,
    double? minRating,
    bool? onSaleOnly,
    String? search,
  }) {
    return ProductFilter(
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      availability: availability ?? this.availability,
      minRating: minRating ?? this.minRating,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      search: search ?? this.search,
    );
  }
}

abstract class ProductRepository {
  Future<List<Product>> getFeatured();
  Future<List<Product>> getNewArrivals();
  Future<List<Product>> getBestSellers();
  Future<List<Product>> getTrending();
  Future<List<Product>> getRecommended({String? customerId});
  Future<CatalogResult> search(
    ProductFilter filter,
    ProductSort sort, {
    int page = 1,
    int pageSize = 20,
  });
  Future<Product?> getById(String id);
  Future<List<Review>> getReviews(String productId);
}

abstract class CategoryRepository {
  Future<List<Category>> getRootCategories();
  Future<List<Category>> getSubcategories(String parentId);
  Future<Category?> getById(String id);
}

abstract class BrandRepository {
  Future<List<Brand>> getAll();
  Future<Brand?> getById(String id);
}
