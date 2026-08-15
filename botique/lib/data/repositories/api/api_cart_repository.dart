import '../../api/api_client.dart';
import '../../../models/cart.dart';
import '../../../models/product.dart';
import '../commerce_repository.dart';

class ApiCartRepository implements CartRepository {
  ApiCartRepository(this._client);

  final ApiClient _client;
  List<CartItem> _cache = [];
  final Map<String, String> _backendIds = {};

  @override
  Future<List<CartItem>> getItems() async {
    final data = await _client.get('/api/cart');
    final rawItems = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    _backendIds.clear();
    for (final e in rawItems.cast<Map<String, dynamic>>()) {
      final productId = e['productId'] as String? ?? '';
      final variantId = e['variantId'] as String?;
      _backendIds['$productId|$variantId'] = e['id'] as String? ?? '';
    }
    final items = rawItems.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    _cache = items;
    return items;
  }

  @override
  Future<void> add(CartItem item) async {
    await _client.post('/api/cart/items', body: {
      'productId': item.product.id,
      if (item.variant != null) 'variantId': item.variant!.id,
      'quantity': item.quantity,
    });
    await getItems();
  }

  @override
  Future<void> remove(String productId, {String? variantId}) async {
    final backendId = await _backendId(productId, variantId);
    if (backendId == null) return;
    await _client.delete('/api/cart/items/$backendId');
    await getItems();
  }

  @override
  Future<void> updateQuantity(String productId, int quantity, {String? variantId}) async {
    final backendId = await _backendId(productId, variantId);
    if (backendId == null) return;
    await _client.patch('/api/cart/items/$backendId', body: {'quantity': quantity});
    await getItems();
  }

  @override
  Future<void> clear() async {
    await _client.delete('/api/cart');
    _cache = [];
    _backendIds.clear();
  }

  Future<String?> _backendId(String productId, String? variantId) async {
    if (_backendIds.isEmpty) await getItems();
    return _backendIds['$productId|$variantId'];
  }
}