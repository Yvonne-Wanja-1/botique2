import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/fashion_beauty_reveal.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';

class SubmitPaymentScreen extends StatefulWidget {
  const SubmitPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderNumber,
  });

  final String orderId;
  final double amount;
  final String orderNumber;

  @override
  State<SubmitPaymentScreen> createState() => _SubmitPaymentScreenState();
}

class _SubmitPaymentScreenState extends State<SubmitPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _noteController = TextEditingController();
  late Future<TransferDetails> _detailsFuture;
  DateTime? _paymentDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount.toStringAsFixed(2),
    );
    _paymentDate = DateTime.now();
    _detailsFuture = context.read<OrderRepository>().getTransferDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _confirmationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  String _dateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final repo = context.read<OrderRepository>();
    await repo.submitPayment(
      SubmitPaymentPayload(
        orderId: widget.orderId,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        paymentDate: _dateString(_paymentDate ?? DateTime.now()),
        confirmationMessage: _confirmationController.text.trim(),
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );

    if (!mounted) return;
    showSuccessSnack(context, 'Payment submitted for verification');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<TransferDetails>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                final details = snapshot.data;
                return BeautyReveal(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How to pay',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _Row(
                            label: 'Paybill',
                            value: details?.paybillNumber ?? '222111',
                          ),
                          const SizedBox(height: 6),
                          _Row(
                            label: 'Account',
                            value: details?.accountNumber ?? '65727',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Order: ${widget.orderNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: QueensTouchColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (KSh)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final value = double.tryParse(v?.trim() ?? '');
                if (value == null || value <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_dateString(_paymentDate ?? DateTime.now())),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'M-Pesa/Family Bank reference (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Confirmation message',
                hintText: 'Paste the full confirmation message you received',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: QueensTouchColors.onGold,
                        ),
                      )
                    : const Text('Submit Payment'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: QueensTouchColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
