import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.categoryId, this.initialQuery});

  final String? categoryId;
  final String? initialQuery;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  ProductFilter _filter = const ProductFilter();
  ProductSort _sort = ProductSort.newest;
  bool _loading = true;
  CatalogResult? _result;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = ProductFilter(categoryId: widget.categoryId, search: widget.initialQuery);
    _searchController.text = widget.initialQuery ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<CatalogService>().search(_filter, _sort);
    if (mounted) setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() async {
    final applied = await showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        current: _filter,
        onApply: (f) => Navigator.pop(context, f),
      ),
    );
    if (applied != null) {
      _filter = applied;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          onSubmitted: (q) {
            _filter = _filter.copyWith(search: q.isEmpty ? null : q);
            _load();
          },
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !_filter.isEmpty,
              label: const Text('1'),
              child: const Icon(Icons.tune),
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : Column(
              children: [
                _SortBar(
                  sort: _sort,
                  total: _result?.total ?? 0,
                  onSort: (s) {
                    setState(() => _sort = s);
                    _load();
                  },
                ),
                Expanded(
                  child: (_result?.products.isEmpty ?? true)
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No products found',
                          message: 'Try adjusting your filters or search terms.',
                        )
                      : _ProductGrid(products: _result!.products),
                ),
              ],
            ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.total, required this.onSort});

  final ProductSort sort;
  final int total;
  final ValueChanged<ProductSort> onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('$total items', style: const TextStyle(color: QueensTouchColors.textMuted)),
          const Spacer(),
          PopupMenuButton<ProductSort>(
            initialValue: sort,
            onSelected: onSort,
            child: Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(sort.label),
            ),
            itemBuilder: (context) => [
              for (final s in ProductSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.onApply});

  final ProductFilter current;
  final ValueChanged<ProductFilter> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductFilter _draft;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _priceRange = RangeValues(
      _draft.minPrice ?? 0,
      _draft.maxPrice ?? 150,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text('Price range', style: TextStyle(fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 200,
                    divisions: 20,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('On sale only'),
                    value: _draft.onSaleOnly,
                    onChanged: (v) => setState(() => _draft = _draft.copyWith(onSaleOnly: v)),
                  ),
                  SwitchListTile(
                    title: const Text('In stock only'),
                    value: _draft.availability == true,
                    onChanged: (v) => setState(() =>
                        _draft = _draft.copyWith(availability: v ? true : null)),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _draft = const ProductFilter();
                              _priceRange = const RangeValues(0, 200);
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final f = _draft.copyWith(
                              minPrice: _priceRange.start == 0 ? null : _priceRange.start,
                              maxPrice: _priceRange.end >= 200 ? null : _priceRange.end,
                            );
                            widget.onApply(f);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
