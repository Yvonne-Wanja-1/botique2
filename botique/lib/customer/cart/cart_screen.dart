import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    if (cart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        message: 'Explore the boutique and find something beautiful.',
        action: TextButton(
          onPressed: null,
          child: Text('Browse Products'),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CartItemTile(item: cart.items[index]),
          ),
        ),
        _CartSummary(cart: cart),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: QueensTouchColors.blushLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checkroom, color: QueensTouchColors.plumLight),
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
                      style: const TextStyle(color: QueensTouchColors.textMuted, fontSize: 12),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.product.effectivePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: QueensTouchColors.plum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => cart.updateQuantity(
                          item.product.id,
                          item.quantity - 1,
                          variantId: item.variant?.id,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => cart.updateQuantity(
                          item.product.id,
                          item.quantity + 1,
                          variantId: item.variant?.id,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: QueensTouchColors.danger),
              onPressed: () => cart.removeItem(item.product.id, variantId: item.variant?.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE4D5DA)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final CartService cart;

  @override
  Widget build(BuildContext context) {
    final shipping = cart.subtotal >= 100 ? 0.0 : 8.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEDFE4))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
            _SummaryRow(label: 'Shipping', value: shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Total',
              value: '\$${(cart.subtotal + shipping).toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
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
  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  final String label;
  final String value;
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
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? QueensTouchColors.plum : null,
            ),
          ),
        ],
      ),
    );
  }
}