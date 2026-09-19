import 'package:flutter/foundation.dart';

import '../data/repositories/commerce_repository.dart';
import '../models/cart.dart';

class WishlistService extends ChangeNotifier {
  WishlistService(this._repository);

  final WishlistRepository _repository;
  List<WishlistItem> _items = [];

  List<WishlistItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  Future<void> load() async {
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> toggle(String productId) async {
    final isCurrentlyInWishlist = _items.any((i) => i.product.id == productId);
    if (isCurrentlyInWishlist) {
      await _repository.remove(productId);
      _items.removeWhere((i) => i.product.id == productId);
    } else {
      await _repository.add(productId);
      _items = await _repository.getItems();
    }
    notifyListeners();
  }

  bool contains(String productId) {
    return _items.any((i) => i.product.id == productId);
  }

  Future<void> remove(String productId) async {
    await _repository.remove(productId);
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }
}
