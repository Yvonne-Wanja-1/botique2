import '../../api/api_client.dart';
import '../../../models/promotion.dart';
import '../commerce_repository.dart';

class ApiPromotionRepository implements PromotionRepository {
  ApiPromotionRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Promotion>> getAll() async {
    final data = await _client.get('/api/promotions');
    final list = (data as List<dynamic>);
    return list.map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Promotion>> getActive() async {
    final data = await _client.get('/api/promotions/active');
    final list = (data as List<dynamic>);
    return list.map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Promotion> create(Promotion promo) async {
    final data = await _client.post('/api/promotions', body: promo.toJson());
    return Promotion.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Promotion> update(Promotion promo) async {
    final data = await _client.put('/api/promotions/${promo.id}', body: promo.toJson());
    return Promotion.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('/api/promotions/$id');
  }

  @override
  Future<Map<String, dynamic>?> validate(String code, double subtotal) async {
    try {
      final data = await _client.post('/api/promotions/validate', body: {'code': code, 'subtotal': subtotal});
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
