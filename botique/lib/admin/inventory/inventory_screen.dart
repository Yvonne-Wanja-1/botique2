import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../models/audit.dart';
import '../../services/auth_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _tab = 0;
  String _query = '';
  List<VariantStock> _variants = [];
  bool _loading = true;
  final List<InventoryTransaction> _history = [];

  static const _tabs = ['Stock', 'Low Stock', 'Out of Stock', 'Stock History'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<InventoryRepository>();
      _variants = await repo.list();
    } catch (_) {
      _variants = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<VariantStock> get _filtered => _variants.where((v) {
        final matchesQuery = _query.isEmpty ||
            v.productName.toLowerCase().contains(_query.toLowerCase()) ||
            v.sku.toLowerCase().contains(_query.toLowerCase());
        return switch (_tab) {
          0 => matchesQuery,
          1 => v.isLowStock,
          2 => v.isOutOfStock,
          _ => true,
        };
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search inventory...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < _tabs.length; i++)
                    ButtonSegment(value: i, label: Text(_tabs[i])),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _tab == 3
              ? _historyView()
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) => _InventoryRow(
                          variant: _filtered[index],
                          onAdjust: (newQty, reason) async {
                            final prev = _filtered[index].stockQty;
                            final diff = newQty - prev;
                            if (diff == 0) return;
                            try {
                              final repo = context.read<InventoryRepository>();
                              final changeType = diff > 0 ? 'add' : 'reduce';
                              final result = await repo.adjust(
                                _filtered[index].variantId,
                                quantity: diff,
                                reason: reason.isEmpty ? 'Manual adjustment' : reason,
                                changeType: changeType,
                              );
                              setState(() {
                                _variants = _variants.map((v) {
                                  if (v.variantId == _filtered[index].variantId && result != null) {
                                    return VariantStock(
                                      variantId: v.variantId,
                                      productId: v.productId,
                                      productName: v.productName,
                                      sku: v.sku,
                                      size: v.size,
                                      color: v.color,
                                      shade: v.shade,
                                      stockQty: result.newQuantity,
                                      stockThreshold: v.stockThreshold,
                                      isLowStock: result.newQuantity > 0 && result.newQuantity <= v.stockThreshold,
                                      isOutOfStock: result.newQuantity == 0,
                                    );
                                  }
                                  return v;
                                }).toList();
                                _history.insert(0, InventoryTransaction(
                                  id: 't${_history.length + 1}',
                                  productId: _filtered[index].productId,
                                  productName: _filtered[index].productName,
                                  type: diff > 0 ? InventoryChangeType.add : InventoryChangeType.reduce,
                                  previousQuantity: prev,
                                  newQuantity: result?.newQuantity ?? newQty,
                                  reason: reason.isEmpty ? 'Manual adjustment' : reason,
                                  staffName: context.read<AuthService>().currentUser?.name,
                                  createdAt: DateTime.now(),
                                ));
                              });
                              if (context.mounted) showSuccessSnack(context, 'Stock updated');
                            } catch (e) {
                              if (context.mounted) showSuccessSnack(context, 'Failed to update stock');
                            }
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _historyView() {
    if (_history.isEmpty) {
      return Center(
        child: Text('No adjustments yet', style: TextStyle(color: QueensTouchColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final t = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              t.type == InventoryChangeType.add ? Icons.add_box : Icons.indeterminate_check_box,
              color: t.type == InventoryChangeType.add ? QueensTouchColors.success : QueensTouchColors.danger,
            ),
            title: Text(t.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${t.previousQuantity} → ${t.newQuantity} · ${t.reason} · ${t.staffName ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${t.quantityChanged > 0 ? '+' : ''}${t.quantityChanged}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.quantityChanged > 0 ? QueensTouchColors.success : QueensTouchColors.danger,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.variant,
    required this.onAdjust,
  });

  final VariantStock variant;
  final void Function(int newQty, String reason) onAdjust;

  @override
  Widget build(BuildContext context) {
    final stockColor = variant.isOutOfStock
        ? QueensTouchColors.danger
        : variant.isLowStock
            ? QueensTouchColors.warning
            : QueensTouchColors.textMuted;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: QueensTouchColors.blushLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.checkroom, color: QueensTouchColors.plumLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    variant.label,
                    style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                  ),
                  Text(
                    'In stock: ${variant.stockQty} · Threshold: ${variant.stockThreshold}',
                    style: TextStyle(fontSize: 12, color: stockColor),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _showAdjustDialog(context),
              child: const Text('Adjust'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustDialog(BuildContext context) {
    final controller = TextEditingController(text: '${variant.stockQty}');
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(variant.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (variant.label.isNotEmpty)
              Text(variant.label, style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New quantity'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty < 0) return;
              Navigator.pop(context);
              onAdjust(qty, reasonController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
