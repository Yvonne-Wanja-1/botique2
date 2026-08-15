import '../../api/api_client.dart';
import '../../../models/product.dart';
import '../../../models/review.dart';
import '../catalog_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._client);

  final ApiClient _client;

  Future<List<Product>> _listByFlag(String flag) async {
    final data = await _client.get('/api/products', query: {flag: 'true'});
    return _productsFromData(data);
  }

  @override
  Future<List<Product>> getFeatured() => _listByFlag('featured');

  @override
  Future<List<Product>> getNewArrivals() => _listByFlag('newArrival');

  @override
  Future<List<Product>> getBestSellers() => _listByFlag('bestSeller');

  @override
  Future<List<Product>> getTrending() => _listByFlag('trending');

  @override
  Future<List<Product>> getRecommended({String? customerId}) async {
    final data = await _client.get('/api/products', query: {'sort': 'best_selling'});
    return _productsFromData(data);
  }

  @override
  Future<CatalogResult> search(ProductFilter filter, ProductSort sort,
      {int page = 1, int pageSize = 20}) async {
    final data = await _client.get('/api/products', query: {
      ..._filterQuery(filter),
      'sort': _sortQuery(sort),
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return CatalogResult(
      products: _productsFromData(data),
      total: (data as Map<String, dynamic>)['total'] as int? ?? 0,
    );
  }

  @override
  Future<Product?> getById(String id) async {
    final data = await _client.get('/api/products/$id');
    return data == null ? null : Product.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    final data = await _client.get('/api/products/$productId/reviews');
    return (data as List<dynamic>)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Product> _productsFromData(Object? data) {
    if (data is! Map<String, dynamic>) return [];
    return (data['products'] as List<dynamic>? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _filterQuery(ProductFilter f) => {
        if (f.categoryId != null) 'categoryId': f.categoryId!,
        if (f.brandId != null) 'brandId': f.brandId!,
        if (f.minPrice != null) 'minPrice': f.minPrice!.toString(),
        if (f.maxPrice != null) 'maxPrice': f.maxPrice!.toString(),
        if (f.minRating != null) 'minRating': f.minRating!.toString(),
        if (f.sizes.isNotEmpty) 'sizes': f.sizes,
        if (f.colors.isNotEmpty) 'colors': f.colors,
        if (f.availability != null) 'availability': f.availability!.toString(),
        if (f.onSaleOnly) 'onSale': 'true',
        if (f.search != null) 'q': f.search!,
      };

  String _sortQuery(ProductSort sort) => switch (sort) {
        ProductSort.newest => 'newest',
        ProductSort.priceLowHigh => 'price_low_high',
        ProductSort.priceHighLow => 'price_high_low',
        ProductSort.bestSelling => 'best_selling',
        ProductSort.bestRated => 'best_rated',
        ProductSort.discount => 'discount',
      };
}