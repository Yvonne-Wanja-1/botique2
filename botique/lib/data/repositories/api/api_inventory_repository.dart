import '../../api/api_client.dart';
import '../inventory_repository.dart';

class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<VariantStock>> list({String? stock}) async {
    final query = <String, dynamic>{};
    if (stock != null) query['stock'] = stock;
    final data = await _client.get('/api/inventory/variants', query: query);
    final rows = data as List<dynamic>? ?? [];
    return rows
        .map((e) => VariantStock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdjustResult?> adjust(
    String variantId, {
    required int quantity,
    required String reason,
    required String changeType,
  }) async {
    final data = await _client.post(
      '/api/inventory/variants/$variantId/adjust',
      body: {
        'quantity': quantity,
        'reason': reason,
        'changeType': changeType,
      },
    );
    if (data == null) return null;
    final map = data as Map<String, dynamic>;
    return AdjustResult(
      newQuantity: (map['newQuantity'] as num?)?.toInt() ?? 0,
      previousQuantity: (map['previousQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}
