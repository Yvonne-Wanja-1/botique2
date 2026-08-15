import 'package:flutter/foundation.dart';

import '../data/repositories/commerce_repository.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  CartService(this._repository);

  final CartRepository _repository;
  List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);

  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> addProduct(Product product, {ProductVariant? variant, int quantity = 1}) async {
    await _repository.add(CartItem(product: product, variant: variant, quantity: quantity));
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> removeItem(String productId, {String? variantId}) async {
    await _repository.remove(productId, variantId: variantId);
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity, {String? variantId}) async {
    await _repository.updateQuantity(productId, quantity, variantId: variantId);
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.clear();
    _items = [];
    notifyListeners();
  }
}