import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/fashion_beauty_reveal.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/shipping.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../orders/submit_payment_screen.dart';

const String kPaybillNumber = '222111';
const String kPaybillAccount = '65727';

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

  bool _installmentRequested = false;
  bool _processing = false;

  String? _promoCode;

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

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      showErrorSnack(context, 'Enter a promo code first');
      return;
    }
    setState(() => _promoCode = code);
    showSuccessSnack(context, 'Promo $code will be applied at checkout');
  }

  double get _subtotal => context.read<CartService>().subtotal;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    final shipping = shippingFor(_subtotal);
    final total = _subtotal + shipping;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Contact & Delivery',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Promo Code',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
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
                OutlinedButton(
                  onPressed: _applyPromo,
                  child: const Text('Apply'),
                ),
              ],
            ),
            if (_promoCode != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: QueensTouchColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_promoCode applied',
                    style: const TextStyle(color: QueensTouchColors.success),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _promoCode = null),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Order Review',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
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
                              formatKsh(item.lineTotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 16),
                    _Row('Subtotal', formatKsh(_subtotal)),
                    _Row(
                      'Shipping',
                      shipping == 0 ? 'Free' : formatKsh(shipping),
                    ),
                    const Divider(height: 16),
                    _Row('Total', formatKsh(total), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment — M-Pesa Paybill',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Paybill Number', value: kPaybillNumber),
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Account Number', value: kPaybillAccount),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    for (final (i, step) in const [
                      'Make the payment using the Paybill number above on your phone.',
                      'Return to Queens\' Touch.',
                      'Paste the Family Bank M-Pesa confirmation message into the payment proof field.',
                      'Submit the payment proof.',
                      'Your payment stays pending verification until an authorized admin confirms it.',
                    ].indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: QueensTouchColors.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${i + 1}. $step',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Request installment payment'),
              subtitle: const Text(
                'Pay in monthly installments (subject to approval)',
              ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: QueensTouchColors.onGold,
                        ),
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
    if (cart.isEmpty) {
      showErrorSnack(context, 'Your cart is empty');
      return;
    }
    setState(() => _processing = true);

    final payload = CheckoutPayload(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      paymentMethod: PaymentMethod.paybill,
      items: [
        for (final item in cart.items)
          OrderItem(
            productId: item.product.id,
            variantId: item.variant?.id,
            productName: item.product.name,
            price: item.product.effectivePrice,
            quantity: item.quantity,
            variantLabel: item.variant?.label,
          ),
      ],
      subtotal: _subtotal,
      promotionCode: _promoCode,
      installmentRequested: _installmentRequested,
    );

    final repo = context.read<OrderRepository>();
    try {
      final order = await repo.placeOrder(payload);
      await cart.clear();

      if (!mounted) return;
      setState(() => _processing = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _ConfirmationScreen(order: order)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      showErrorSnack(context, 'Could not place your order: $e');
    }
  }
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
              color: isTotal ? QueensTouchColors.gold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: QueensTouchColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ConfirmationScreen extends StatelessWidget {
  const _ConfirmationScreen({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BeautyReveal(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: QueensTouchColors.success,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you, ${order.customerName}!',
                style: QueensTouchTheme.brandSerif(
                  fontSize: 26,
                  weight: FontWeight.w700,
                ),
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
                      Text(
                        'Order Number',
                        style: const TextStyle(
                          color: QueensTouchColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: QueensTouchColors.gold,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Order Total',
                        style: const TextStyle(
                          color: QueensTouchColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatKsh(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      if (order.installmentRequested) ...[
                        const Divider(height: 24),
                        const Text(
                          'Installment requested',
                          style: TextStyle(color: QueensTouchColors.warning),
                        ),
                        const Text(
                          'Awaiting approval',
                          style: TextStyle(
                            color: QueensTouchColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      const Text(
                        'How to pay',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const _Row('Paybill Number', kPaybillNumber),
                      const _Row('Account Number', kPaybillAccount),
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
                          child: const Text('Submit Payment Proof'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}