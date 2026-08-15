import '../../api/api_client.dart';
import '../../../models/category.dart';
import '../catalog_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Category>> getRootCategories() async {
    final data = await _client.get('/api/categories');
    return (data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Category>> getSubcategories(String parentId) async {
    final data = await _client.get('/api/categories/$parentId/subcategories');
    return (data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final roots = await getRootCategories();
    for (final c in roots) {
      if (c.id == id) return c;
    }
    for (final c in roots) {
      for (final s in await getSubcategories(c.id)) {
        if (s.id == id) return s;
      }
    }
    return null;
  }
}