import 'dart:async';

import '../../models/cart.dart';
import '../../models/order.dart';
import '../../models/promotion.dart';
import '../mock/mock_catalog_data.dart';
import '../repositories/commerce_repository.dart';

class MockCartRepository implements CartRepository {
  final List<CartItem> _items = [];

  @override
  Future<List<CartItem>> getItems() async => List.of(_items);

  @override
  Future<void> add(CartItem item) async {
    final idx = _items.indexWhere(
      (i) => i.product.id == item.product.id && i.variant?.id == item.variant?.id,
    );
    if (idx >= 0) {
      final current = _items[idx];
      _items[idx] = current.copyWith(quantity: current.quantity + item.quantity);
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> remove(String productId, {String? variantId}) async {
    _items.removeWhere(
      (i) => i.product.id == productId && (variantId == null || i.variant?.id == variantId),
    );
  }

  @override
  Future<void> updateQuantity(String productId, int quantity, {String? variantId}) async {
    final idx = _items.indexWhere(
      (i) => i.product.id == productId && (variantId == null || i.variant?.id == variantId),
    );
    if (idx >= 0) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx] = _items[idx].copyWith(quantity: quantity);
      }
    }
  }

  @override
  Future<void> clear() async => _items.clear();
}

class MockWishlistRepository implements WishlistRepository {
  final List<WishlistItem> _items = [];

  @override
  Future<List<WishlistItem>> getItems() async => List.of(_items);

  @override
  Future<void> add(String productId) async {
    final product = MockCatalogData.products.where((p) => p.id == productId).firstOrNull;
    if (product != null && !_items.any((i) => i.product.id == productId)) {
      _items.add(WishlistItem(product: product, addedAt: DateTime.now()));
    }
  }

  @override
  Future<void> remove(String productId) async {
    _items.removeWhere((i) => i.product.id == productId);
  }

  @override
  Future<bool> contains(String productId) async {
    return _items.any((i) => i.product.id == productId);
  }
}

class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  final List<Payment> _payments = [];
  final List<Installment> _installments = [];
  int _orderSeq = 1000;

  @override
  Future<List<Order>> getOrders({String? customerId}) async {
    return List.of(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Order?> getById(String id) async {
    return _orders.where((o) => o.id == id).firstOrNull;
  }

  @override
  Future<Order> placeOrder(CheckoutPayload payload) async {
    _orderSeq++;
    final order = Order(
      id: 'ord-$_orderSeq',
      orderNumber: 'QT-${DateTime.now().year}-$_orderSeq',
      customerId: payload.customerEmail,
      customerName: payload.customerName,
      customerPhone: payload.customerPhone,
      customerEmail: payload.customerEmail,
      shippingAddress: payload.shippingAddress,
      items: payload.items,
      subtotal: payload.subtotal,
      discount: payload.discount,
      status: payload.installmentRequested ? OrderStatus.pending : OrderStatus.paid,
      paymentStatus: payload.installmentRequested
          ? PaymentStatus.pending
          : payload.paymentMethod == PaymentMethod.cashOnDelivery
              ? PaymentStatus.pending
              : PaymentStatus.successful,
      paymentMethod: payload.paymentMethod,
      installmentRequested: payload.installmentRequested,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<List<Payment>> getPayments({String? customerId}) async {
    final list = List.of(_payments);
    list.sort((a, b) {
      final at = a.createdAt ?? DateTime(1970);
      final bt = b.createdAt ?? DateTime(1970);
      return bt.compareTo(at);
    });
    return list;
  }

  @override
  Future<List<Installment>> getInstallments({String? customerId}) async {
    return List.of(_installments);
  }
}

class MockPromotionRepository {
  final List<Promotion> _promotions = [
    const Promotion(
      id: 'promo1',
      code: 'QUEEN10',
      title: 'Welcome 10% Off',
      type: PromotionType.percentage,
      value: 10,
      minimumOrderAmount: 50,
      isActive: true,
    ),
    const Promotion(
      id: 'promo2',
      code: 'ROYAL20',
      title: 'Royal 20% Off',
      type: PromotionType.percentage,
      value: 20,
      minimumOrderAmount: 100,
      maximumDiscount: 50,
      isActive: true,
    ),
    const Promotion(
      id: 'promo3',
      code: 'FLAT15',
      title: 'Flat 15 Off',
      type: PromotionType.fixed,
      value: 15,
      minimumOrderAmount: 75,
      isActive: true,
    ),
  ];

  Future<List<Promotion>> getAll() async => _promotions;

  Future<Promotion?> findByCode(String code) async {
    for (final p in _promotions) {
      if (p.code.toLowerCase() == code.toLowerCase()) return p;
    }
    return null;
  }
}
