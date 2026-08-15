import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/mock/mock_catalog_data.dart';
import '../../models/audit.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _tab = 0;
  String _query = '';
  final List<InventoryTransaction> _history = [];

  static const _tabs = ['Stock', 'Low Stock', 'Out of Stock', 'Stock History'];

  List<Product> get _products => MockCatalogData.products.where((p) {
        final matchesQuery = _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
        return switch (_tab) {
          0 => matchesQuery,
          1 => p.isLowStock,
          2 => p.isOutOfStock,
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) => _InventoryRow(
                    product: _products[index],
                    staffName: context.read<AuthService>().currentUser?.name ?? 'Staff',
                    onAdjust: (newQty, reason) {
                      final prev = _products[index].totalStock;
                      setState(() {
                        _history.insert(0, InventoryTransaction(
                          id: 't${_history.length + 1}',
                          productId: _products[index].id,
                          productName: _products[index].name,
                          type: newQty > prev ? InventoryChangeType.add : InventoryChangeType.reduce,
                          previousQuantity: prev,
                          newQuantity: newQty,
                          reason: reason,
                          staffName: context.read<AuthService>().currentUser?.name,
                          createdAt: DateTime.now(),
                        ));
                      });
                      showSuccessSnack(context, 'Stock updated to $newQty');
                    },
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
    required this.product,
    required this.onAdjust,
    required this.staffName,
  });

  final Product product;
  final void Function(int newQty, String reason) onAdjust;
  final String staffName;

  @override
  Widget build(BuildContext context) {
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
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'In stock: ${product.totalStock} · Threshold: ${product.stockThreshold}',
                    style: TextStyle(fontSize: 12, color: product.isLowStock ? QueensTouchColors.warning : QueensTouchColors.textMuted),
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
    final controller = TextEditingController(text: '${product.totalStock}');
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              onAdjust(qty, reasonController.text.isEmpty ? 'Manual adjustment' : reasonController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}