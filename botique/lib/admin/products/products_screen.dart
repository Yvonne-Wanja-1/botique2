import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/mock/mock_catalog_data.dart';
import '../../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  final TextEditingController _search = TextEditingController();

  List<Product> get _filtered {
    final q = _query.toLowerCase();
    final list = MockCatalogData.products;
    if (q.isEmpty) return list;
    return list.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => showSuccessSnack(context, 'Product creation form coming with backend'),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final p = _filtered[index];
              return _ProductRow(
                product: p,
                onEdit: () => showSuccessSnack(context, 'Edit coming with backend'),
                onToggle: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Deactivate product?',
                    message: '${p.name} will no longer be visible in the storefront.',
                    isDanger: true,
                  );
                  if (ok) showSuccessSnack(context, 'Product deactivated');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onToggle,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: QueensTouchColors.blushLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.checkroom, color: QueensTouchColors.plumLight),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.id.toUpperCase()} · Stock: ${product.totalStock}'),
            Text(
              '\$${product.effectivePrice.toStringAsFixed(2)}',
              style: const TextStyle(color: QueensTouchColors.plum, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(product: product),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'toggle') onToggle();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'toggle', child: Text('Deactivate')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final (label, color) = product.isOutOfStock
        ? ('Out of stock', QueensTouchColors.danger)
        : product.isLowStock
            ? ('Low stock', QueensTouchColors.warning)
            : ('Active', QueensTouchColors.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}