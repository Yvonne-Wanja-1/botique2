import '../../api/api_client.dart';
import '../../../models/brand.dart';
import '../catalog_repository.dart';

class ApiBrandRepository implements BrandRepository {
  ApiBrandRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Brand>> getAll() async {
    final data = await _client.get('/api/brands');
    return (data as List<dynamic>)
        .map((e) => Brand.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Brand?> getById(String id) async {
    for (final b in await getAll()) {
      if (b.id == id) return b;
    }
    return null;
  }
}