import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/category.dart';
import '../../services/catalog_service.dart';
import 'catalog_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    if (catalog.loading) return const LoadingView();

    final roots = catalog.rootCategories;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final root in roots) _CategorySection(category: root),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogService>();

    return FutureBuilder<List<Category>>(
      future: catalog.getSubcategories(category.id),
      builder: (context, snapshot) {
        final subs = snapshot.data ?? const <Category>[];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      category.id == 'clothing'
                          ? Icons.checkroom
                          : Icons.face_retouching_natural,
                      color: QueensTouchColors.plum,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CatalogScreen(categoryId: category.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.description!,
                    style: const TextStyle(color: QueensTouchColors.textMuted, fontSize: 13),
                  ),
                ],
                if (subs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sub in subs)
                        ActionChip(
                          label: Text(sub.name),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CatalogScreen(categoryId: sub.id),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
