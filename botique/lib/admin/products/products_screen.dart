import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/image_url.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/product.dart';
import '../../services/admin_catalog_service.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCatalogService>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (created == true && mounted) {
      showSuccessSnack(context, product == null ? 'Product created' : 'Product updated');
    }
  }

  Future<void> _toggle(Product product) async {
    final service = context.read<AdminCatalogService>();
    final ok = await confirmDialog(
      context,
      title: 'Deactivate product?',
      message: '${product.name} will no longer be visible in the storefront.',
      isDanger: true,
    );
    if (ok) {
      try {
        await service.deactivate(product.id);
        if (mounted) showSuccessSnack(context, 'Product deactivated');
      } catch (e) {
        if (mounted) showErrorSnack(context, 'Failed to deactivate: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AdminCatalogService>();
    final list = service.products;
    final q = _query.toLowerCase();
    final filtered = q.isEmpty ? list : list.where((p) => p.name.toLowerCase().contains(q)).toList();

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
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),
        if (service.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(service.error!, style: const TextStyle(color: QueensTouchColors.danger)),
          ),
        Expanded(
          child: service.loading && service.products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products',
                      message: 'Add a product to get started.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return _ProductRow(
                          product: p,
                          onEdit: () => _openForm(product: p),
                          onToggle: () => _toggle(p),
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
          clipBehavior: Clip.antiAlias,
          child: product.images.isEmpty
              ? const Icon(Icons.checkroom, color: QueensTouchColors.plumLight)
              : Image.network(
                  resolveImageUrl(product.images.first),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.checkroom, color: QueensTouchColors.plumLight),
                ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.id.toUpperCase()} · Stock: ${product.totalStock}'),
            Text(
              formatKsh(product.effectivePrice),
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
    final (label, color) = product.status == ProductStatus.inactive
        ? ('Inactive', QueensTouchColors.textMuted)
        : product.isOutOfStock
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