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
    if (await _repository.contains(productId)) {
      await _repository.remove(productId);
    } else {
      await _repository.add(productId);
    }
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<bool> contains(String productId) async {
    return _repository.contains(productId);
  }

  Future<void> remove(String productId) async {
    await _repository.remove(productId);
    _items = await _repository.getItems();
    notifyListeners();
  }
}