import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/mock/mock_commerce_repositories.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';
import '../../models/promotion.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../orders/submit_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _promoController = TextEditingController();

  PaymentMethod _method = PaymentMethod.paybill;
  bool _installmentRequested = false;
  bool _processing = false;

  Promotion? _appliedPromo;
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() async {
    final repo = MockPromotionRepository();
    final promo = await repo.findByCode(_promoController.text.trim());
    if (!mounted) return;
    if (promo == null || !promo.isActive) {
      showErrorSnack(context, 'Invalid or inactive promo code');
      return;
    }
    setState(() {
      _appliedPromo = promo;
      _discount = promo.discountFor(_subtotal);
    });
    showSuccessSnack(context, 'Promo ${promo.code} applied');
  }

  double get _subtotal => context.read<CartService>().subtotal;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    final shipping = _subtotal >= 100 ? 0.0 : 8.0;
    final total = _subtotal - _discount + shipping;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Contact & Delivery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Delivery address'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text('Promo Code', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(hintText: 'e.g. QUEEN10'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _applyPromo, child: const Text('Apply')),
              ],
            ),
            if (_appliedPromo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: QueensTouchColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_appliedPromo!.code} applied',
                    style: const TextStyle(color: QueensTouchColors.success),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _appliedPromo = null;
                      _discount = 0;
                    }),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text('Order Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final item in cart.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name}${item.variant != null ? ' (${item.variant!.label})' : ''} × ${item.quantity}',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\$${item.lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 16),
                    _Row('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                    if (_discount > 0)
                      _Row('Discount', '-\$${_discount.toStringAsFixed(2)}'),
                    _Row('Shipping', shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _Row('Total', '\$${total.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final method in PaymentMethod.values)
              RadioListTile<PaymentMethod>(
                title: Text(_methodLabel(method)),
                value: method,
                groupValue: _method,
                dense: true,
                onChanged: (v) => setState(() => _method = v!),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Request installment payment'),
              subtitle: const Text('Pay in monthly installments (subject to approval)'),
              value: _installmentRequested,
              onChanged: (v) => setState(() => _installmentRequested = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : () => _placeOrder(cart, total),
                child: _processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Place Order'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(CartService cart, double total) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);

    final payload = CheckoutPayload(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      paymentMethod: _method,
      items: [
        for (final item in cart.items)
          OrderItem(
            productId: item.product.id,
            productName: item.product.name,
            price: item.product.effectivePrice,
            quantity: item.quantity,
            variantLabel: item.variant?.label,
          ),
      ],
      subtotal: _subtotal,
      discount: _discount,
      promotionCode: _appliedPromo?.code,
      installmentRequested: _installmentRequested,
    );

    final repo = context.read<OrderRepository>();
    final order = await repo.placeOrder(payload);
    await cart.clear();

    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _ConfirmationScreen(order: order),
      ),
    );
  }

  String _methodLabel(PaymentMethod m) => switch (m) {
        PaymentMethod.cashOnDelivery => 'Cash on Delivery',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.paybill => 'Paybill',
        PaymentMethod.card => 'Card Payment',
        PaymentMethod.installment => 'Installment',
      };
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.isTotal = false});

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
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? QueensTouchColors.plum : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationScreen extends StatelessWidget {
  const _ConfirmationScreen({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: QueensTouchColors.success, size: 80),
            const SizedBox(height: 16),
            Text(
              'Thank you, ${order.customerName}!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Order Number', style: const TextStyle(color: QueensTouchColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: QueensTouchColors.plum),
                    ),
                    const Divider(height: 24),
                    Text('Order Total', style: const TextStyle(color: QueensTouchColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    if (order.installmentRequested) ...[
                      const Divider(height: 24),
                      const Text('Installment requested', style: TextStyle(color: QueensTouchColors.warning)),
                      const Text('Awaiting approval', style: TextStyle(color: QueensTouchColors.warning, fontSize: 13)),
                    ],
                    if (order.paymentMethod == PaymentMethod.paybill ||
                        order.paymentMethod == PaymentMethod.bankTransfer) ...[
                      const Divider(height: 24),
                      const Text('How to pay', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const _Row('Paybill', '222111'),
                      const _Row('Account', '65727'),
                      _Row('Total', formatKsh(order.total), isTotal: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SubmitPaymentScreen(
                                orderId: order.id,
                                orderNumber: order.orderNumber,
                                amount: order.total,
                              ),
                            ),
                          ),
                          child: const Text('Pay'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}