import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../data/repositories/catalog_repository.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Admin-focused product management backed by the shared product/category/brand
/// repositories. Consumed by the Products section and the product form.
class AdminCatalogService extends ChangeNotifier {
  AdminCatalogService(this._productRepo, this._categoryRepo, this._brandRepo);

  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final BrandRepository _brandRepo;

  bool _loading = false;
  String? _error;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _productRepo.getAll(),
        _categoryRepo.getRootCategories(),
        _brandRepo.getAll(),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _brands = results[2] as List<Brand>;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Product> create(ProductDraft draft) async {
    final product = await _productRepo.create(draft);
    await load();
    return product;
  }

  Future<Product> update(String id, ProductDraft draft) async {
    final product = await _productRepo.update(id, draft);
    await load();
    return product;
  }

  Future<void> deactivate(String id) async {
    await _productRepo.deactivate(id);
    await load();
  }

  Future<Product?> getById(String id) => _productRepo.getById(id);

  Future<List<Category>> getSubcategories(String parentId) =>
      _categoryRepo.getSubcategories(parentId);

  Future<List<ProductImage>> getImages(String productId) => _productRepo.getImages(productId);

  Future<List<ProductImage>> uploadImages(String productId, List<UploadImage> images) =>
      _productRepo.uploadImages(productId, images);

  Future<void> deleteImage(String productId, String imageId) =>
      _productRepo.deleteImage(productId, imageId);

  Future<ProductImage> setPrimaryImage(String productId, String imageId) =>
      _productRepo.setPrimaryImage(productId, imageId);
}