import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../data/repositories/catalog_repository.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';

class CatalogService extends ChangeNotifier {
  CatalogService(this._productRepo, this._categoryRepo);

  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;

  bool _loading = false;
  String? _error;
  List<Product> _featured = [];
  List<Product> _newArrivals = [];
  List<Product> _bestSellers = [];
  List<Product> _trending = [];
  List<Product> _recommended = [];
  List<Category> _rootCategories = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Product> get featured => _featured;
  List<Product> get newArrivals => _newArrivals;
  List<Product> get bestSellers => _bestSellers;
  List<Product> get trending => _trending;
  List<Product> get recommended => _recommended;
  List<Category> get rootCategories => _rootCategories;

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _productRepo.getFeatured(),
        _productRepo.getNewArrivals(),
        _productRepo.getBestSellers(),
        _productRepo.getTrending(),
        _productRepo.getRecommended(),
        _categoryRepo.getRootCategories(),
      ]);
      _featured = results[0] as List<Product>;
      _newArrivals = results[1] as List<Product>;
      _bestSellers = results[2] as List<Product>;
      _trending = results[3] as List<Product>;
      _recommended = results[4] as List<Product>;
      _rootCategories = results[5] as List<Category>;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<List<Category>> getSubcategories(String parentId) {
    return _categoryRepo.getSubcategories(parentId);
  }

  Future<Product?> getProduct(String id) => _productRepo.getById(id);

  Future<List<Review>> getReviews(String productId) => _productRepo.getReviews(productId);

  Future<CatalogResult> search(ProductFilter filter, ProductSort sort, {int page = 1, int pageSize = 20}) {
    return _productRepo.search(filter, sort, page: page, pageSize: pageSize);
  }
}