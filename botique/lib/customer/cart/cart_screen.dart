import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animated_counter.dart';
import '../../core/animations/product_image_reveal.dart';
import '../../core/animations/product_presentation.dart';
import '../../core/animations/qts_animation.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/shipping.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return AnimatedSwitcher(
      duration: QtMotion.reduceMotion(context) ? Duration.zero : QtMotion.normal,
      child: cart.isEmpty
          ? const EmptyState(
              key: ValueKey('cart-empty'),
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Explore the boutique and find something beautiful.',
              action: TextButton(
                onPressed: null,
                child: Text('Browse Products'),
              ),
            )
          : Column(
              key: const ValueKey('cart-filled'),
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                      key: ValueKey(
                        'cart-item-${cart.items[index].product.id}-${cart.items[index].variant?.id}',
                      ),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: QtMotion.reduceMotion(context)
                          ? Duration.zero
                          : QtMotion.normal,
                      curve: QtMotion.signature,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: _CartItemTile(item: cart.items[index]),
                    ),
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _updateQuantity(CartService cart, int newQty) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        await cart.updateQuantity(
          widget.item.product.id,
          newQty,
          variantId: widget.item.variant?.id,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    final item = widget.item;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ProductImageReveal(
                imageUrl: item.product.images.isNotEmpty
                    ? item.product.images.first
                    : '',
                borderRadius: BorderRadius.circular(12),
                presentation: presentationFor(
                  categorySlug: item.product.categorySlug,
                  categoryId: item.product.categoryId,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variant != null)
                    Text(
                      item.variant!.label,
                      style: const TextStyle(
                        color: QueensTouchColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    formatKsh(item.product.effectivePrice),
                    style: const TextStyle(
                      color: QueensTouchColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        enabled: item.quantity > 1,
                        onTap: () => _updateQuantity(cart, item.quantity - 1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => _updateQuantity(cart, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: QueensTouchColors.danger,
              ),
              onPressed: () =>
                  cart.removeItem(item.product.id, variantId: item.variant?.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.enabled = true});

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled
                  ? QueensTouchColors.surfaceBorder
                  : QueensTouchColors.surfaceBorder.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? null : QueensTouchColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CartSummary extends StatefulWidget {
  const _CartSummary({required this.cart});

  final CartService cart;

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<_CartSummary> {
  DeliveryMethod _deliveryMethod = DeliveryMethod.delivery;

  @override
  Widget build(BuildContext context) {
    final shipping = shippingFor(widget.cart.subtotal, method: _deliveryMethod);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: QueensTouchColors.surfaceLight,
        border: Border(top: BorderSide(color: QueensTouchColors.surfaceBorder)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: AnimatedCounter(
                value: widget.cart.subtotal,
                format: formatKsh,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Fulfillment', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<DeliveryMethod>(
                    segments: const [
                      ButtonSegment(
                        value: DeliveryMethod.pickup,
                        label: Text('Pickup', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.store_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: DeliveryMethod.delivery,
                        label: Text('Delivery', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.local_shipping_outlined, size: 16),
                      ),
                    ],
                    selected: {_deliveryMethod},
                    onSelectionChanged: (v) => setState(() => _deliveryMethod = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            _SummaryRow(
              label: _deliveryMethod == DeliveryMethod.delivery ? 'Delivery Fee' : 'Delivery Fee',
              value: Text(
                _deliveryMethod == DeliveryMethod.pickup ? 'Free' : formatKsh(shipping),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _deliveryMethod == DeliveryMethod.pickup ? QueensTouchColors.success : null,
                ),
              ),
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Total',
              isTotal: true,
              value: AnimatedCounter(
                value: widget.cart.subtotal + shipping,
                format: formatKsh,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: QueensTouchColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(deliveryMethod: _deliveryMethod),
                    ),
                  );
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final Widget value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          value,
        ],
      ),
    );
  }
}
