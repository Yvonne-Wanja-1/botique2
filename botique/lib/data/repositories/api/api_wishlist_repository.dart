import '../../api/api_client.dart';
import '../../../models/cart.dart';
import '../../../models/product.dart';
import '../commerce_repository.dart';

class ApiWishlistRepository implements WishlistRepository {
  ApiWishlistRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WishlistItem>> getItems() async {
    final data = await _client.get('/api/cart/wishlist');
    return (data as List<dynamic>)
        .map((e) {
          final json = Map<String, dynamic>.from(e as Map<String, dynamic>);
          json['id'] = json['productId'];
          final product = Product.fromJson(json);
          return WishlistItem(product: product, addedAt: null);
        })
        .toList();
  }

  @override
  Future<void> add(String productId) async {
    await _client.post('/api/cart/wishlist/$productId');
  }

  @override
  Future<void> remove(String productId) async {
    await _client.delete('/api/cart/wishlist/$productId');
  }

  @override
  Future<bool> contains(String productId) async {
    final items = await getItems();
    return items.any((i) => i.product.id == productId);
  }
}