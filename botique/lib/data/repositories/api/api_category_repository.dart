import '../../api/api_client.dart';
import '../../../models/category.dart';
import '../catalog_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._client);

  final ApiClient _client;
  List<Category>? _rootsCache;
  final Map<String, List<Category>> _subcategoriesCache = {};

  @override
  Future<List<Category>> getRootCategories() async {
    if (_rootsCache != null) return _rootsCache!;
    final data = await _client.get('/api/categories');
    _rootsCache = (data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    return _rootsCache!;
  }

  @override
  Future<List<Category>> getSubcategories(String parentId) async {
    if (_subcategoriesCache.containsKey(parentId)) {
      return _subcategoriesCache[parentId]!;
    }
    final data = await _client.get('/api/categories/$parentId/subcategories');
    final subs = (data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    _subcategoriesCache[parentId] = subs;
    return subs;
  }

  @override
  Future<Category?> getById(String id) async {
    final roots = await getRootCategories();
    for (final c in roots) {
      if (c.id == id) return c;
    }
    for (final c in roots) {
      final subs = await getSubcategories(c.id);
      for (final s in subs) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  void clearCache() {
    _rootsCache = null;
    _subcategoriesCache.clear();
  }
}
