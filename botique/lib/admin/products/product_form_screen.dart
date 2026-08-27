import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/image_url.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/admin_catalog_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product, this.picker});

  final Product? product;
  final ImagePicker? picker;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ImagePicker _picker;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _discountPrice = TextEditingController();
  final _stockThreshold = TextEditingController();

  Category? _rootCategory;
  Category? _subcategory;
  List<Category> _subcategories = [];
  Brand? _brand;
  bool _featured = false;
  bool _newArrival = false;
  bool _bestSeller = false;
  bool _trending = false;

  final List<_VariantField> _variants = [];
  List<ProductImage> _existingImages = [];
  final List<_PickedImage> _picked = [];
  bool _saving = false;
  bool _picking = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _picker = widget.picker ?? ImagePicker();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final service = context.read<AdminCatalogService>();
    if (widget.product != null) {
      final p = widget.product!;
      _name.text = p.name;
      _description.text = p.description;
      _price.text = p.price.toStringAsFixed(2);
      if (p.discountPrice != null) _discountPrice.text = p.discountPrice!.toStringAsFixed(2);
      _stockThreshold.text = p.stockThreshold.toString();
      _featured = p.hasLabel(ProductLabel.featured);
      _newArrival = p.hasLabel(ProductLabel.newArrival);
      _bestSeller = p.hasLabel(ProductLabel.bestSeller);
      _trending = p.hasLabel(ProductLabel.trending);
      final root = service.categories.where((c) => c.id == p.categoryId).firstOrNull;
      if (root != null) {
        _rootCategory = root;
      } else {
        for (final root in service.categories) {
          final subs = await service.getSubcategories(root.id);
          final match = subs.where((c) => c.id == p.categoryId).firstOrNull;
          if (match != null) {
            _rootCategory = root;
            _subcategory = match;
            _subcategories = subs;
            break;
          }
        }
      }
      _brand = service.brands.where((b) => b.id == p.brandId).firstOrNull;
      for (final v in p.variants) {
        _variants.add(_VariantField.fromVariant(v));
      }
      _existingImages = await service.getImages(p.id);
    } else {
      _stockThreshold.text = '5';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _discountPrice.dispose();
    _stockThreshold.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_picking) return;
    _picking = true;
    try {
      final files = await _picker.pickMultiImage();
      if (files.isEmpty) return;
      final images = <_PickedImage>[];
      for (final file in files) {
        images.add(_PickedImage(
          bytes: await file.readAsBytes(),
          filename: file.name,
          mimeType: file.mimeType ?? 'image/jpeg',
        ));
      }
      if (mounted) setState(() => _picked.addAll(images));
    } finally {
      _picking = false;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AdminCatalogService>();
    final categoryId = _subcategory?.id ?? _rootCategory?.id;
    if (categoryId == null || _brand == null) {
      showErrorSnack(context, 'Select a category and brand');
      return;
    }
    final basePrice = double.tryParse(_price.text) ?? 0;
    final discountPrice = _discountPrice.text.trim().isEmpty
        ? null
        : double.tryParse(_discountPrice.text);
    if (basePrice <= 0) {
      showErrorSnack(context, 'Enter a valid base price');
      return;
    }
    final draft = ProductDraft(
      name: _name.text.trim(),
      description: _description.text.trim(),
      categoryId: categoryId,
      brandId: _brand!.id,
      basePrice: basePrice,
      discountPrice: discountPrice,
      stockThreshold: int.tryParse(_stockThreshold.text) ?? 5,
      isFeatured: _featured,
      isNewArrival: _newArrival,
      isBestSeller: _bestSeller,
      isTrending: _trending,
      variants: [
        for (final v in _variants)
          if (v.sku.text.trim().isNotEmpty)
            ProductVariantDraft(
              sku: v.sku.text.trim(),
              size: _emptyToNull(v.size.text),
              color: _emptyToNull(v.color.text),
              shade: _emptyToNull(v.shade.text),
              price: double.tryParse(v.price.text),
              stockQty: int.tryParse(v.stock.text) ?? 0,
            ),
      ],
    );

    setState(() => _saving = true);
    try {
      final Product product;
      if (_isEditing) {
        product = await service.update(widget.product!.id, draft);
      } else {
        product = await service.create(draft);
      }
      if (_picked.isNotEmpty) {
        await service.uploadImages(
          product.id,
          [for (final i in _picked) UploadImage(bytes: i.bytes, filename: i.filename, mimeType: i.mimeType)],
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnack(context, 'Save failed: $e');
      }
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _removeImage(ProductImage image) async {
    final service = context.read<AdminCatalogService>();
    final ok = await confirmDialog(
      context,
      title: 'Remove image?',
      message: 'This image will be deleted permanently.',
      isDanger: true,
    );
    if (!ok) return;
    try {
      await service.deleteImage(widget.product!.id, image.id);
      setState(() => _existingImages =
          _existingImages.where((i) => i.id != image.id).toList());
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Failed to remove image: $e');
    }
  }

  Future<void> _setPrimary(ProductImage image) async {
    try {
      final updated = await context
          .read<AdminCatalogService>()
          .setPrimaryImage(widget.product!.id, image.id);
      setState(() {
        _existingImages = [
          for (final i in _existingImages)
            if (i.id == updated.id)
              ProductImage(id: i.id, url: i.url, position: 0, isPrimary: true)
            else
              ProductImage(id: i.id, url: i.url, position: i.position, isPrimary: false),
        ];
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Failed to set primary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AdminCatalogService>();
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product name'),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              initialValue: _rootCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in service.categories)
                  DropdownMenuItem(value: c, child: Text(c.name)),
              ],
              onChanged: (c) async {
                setState(() {
                  _rootCategory = c;
                  _subcategory = null;
                  _subcategories = [];
                });
                if (c != null) {
                  final subs = await context.read<AdminCatalogService>().getSubcategories(c.id);
                  if (mounted) setState(() => _subcategories = subs);
                }
              },
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            if (_subcategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Category>(
                initialValue: _subcategory,
                decoration: const InputDecoration(labelText: 'Subcategory'),
                items: [
                  for (final c in _subcategories)
                    DropdownMenuItem(value: c, child: Text(c.name)),
                ],
                onChanged: (c) => setState(() => _subcategory = c),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<Brand>(
              initialValue: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
              items: [
                for (final b in service.brands)
                  DropdownMenuItem(value: b, child: Text(b.name)),
              ],
              onChanged: (b) => setState(() => _brand = b),
              validator: (v) => v == null ? 'Select a brand' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Base price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final value = double.tryParse(v ?? '');
                      return (value == null || value <= 0) ? 'Enter a valid price' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountPrice,
                    decoration: const InputDecoration(labelText: 'Discount price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockThreshold,
              decoration: const InputDecoration(labelText: 'Stock threshold'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Featured'),
                  selected: _featured,
                  onSelected: (v) => setState(() => _featured = v),
                ),
                FilterChip(
                  label: const Text('New Arrival'),
                  selected: _newArrival,
                  onSelected: (v) => setState(() => _newArrival = v),
                ),
                FilterChip(
                  label: const Text('Best Seller'),
                  selected: _bestSeller,
                  onSelected: (v) => setState(() => _bestSeller = v),
                ),
                FilterChip(
                  label: const Text('Trending'),
                  selected: _trending,
                  onSelected: (v) => setState(() => _trending = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Variants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _variants.length; i++) ...[
              _VariantEditor(
                field: _variants[i],
                onRemove: () => setState(() => _variants.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _variants.add(_VariantField())),
                icon: const Icon(Icons.add),
                label: const Text('Add Variant'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_isEditing && _existingImages.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final image in _existingImages)
                    _ExistingImageTile(
                      image: image,
                      onRemove: () => _removeImage(image),
                      onSetPrimary: () => _setPrimary(image),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_picked.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _picked.length; i++)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: QueensTouchColors.blushLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.memory(_picked[i].bytes, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _picked.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_back, size: 14),
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                        final tmp = _picked[i];
                                        _picked[i] = _picked[i - 1];
                                        _picked[i - 1] = tmp;
                                      }),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              onPressed: i == _picked.length - 1
                                  ? null
                                  : () => setState(() {
                                        final tmp = _picked[i];
                                        _picked[i] = _picked[i + 1];
                                        _picked[i + 1] = tmp;
                                      }),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Images'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantField {
  _VariantField();

  factory _VariantField.fromVariant(ProductVariant variant) {
    final field = _VariantField()
      ..sku.text = variant.sku ?? ''
      ..size.text = variant.size ?? ''
      ..color.text = variant.color ?? ''
      ..shade.text = variant.shade ?? ''
      ..price.text = variant.quantity == 0 ? '' : ''
      ..stock.text = variant.quantity.toString();
    return field;
  }

  final sku = TextEditingController();
  final size = TextEditingController();
  final color = TextEditingController();
  final shade = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
}

class _VariantEditor extends StatelessWidget {
  const _VariantEditor({required this.field, required this.onRemove});

  final _VariantField field;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: field.sku,
                    decoration: const InputDecoration(labelText: 'SKU', isDense: true),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: QueensTouchColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: field.size,
                    decoration: const InputDecoration(labelText: 'Size', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: field.color,
                    decoration: const InputDecoration(labelText: 'Color', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: field.shade,
                    decoration: const InputDecoration(labelText: 'Shade', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: field.price,
                    decoration: const InputDecoration(labelText: 'Price', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: field.stock,
                    decoration: const InputDecoration(labelText: 'Stock', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingImageTile extends StatelessWidget {
  const _ExistingImageTile({
    required this.image,
    required this.onRemove,
    required this.onSetPrimary,
  });

  final ProductImage image;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: QueensTouchColors.blushLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            resolveImageUrl(image.url),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image, color: QueensTouchColors.plumLight),
          ),
        ),
        if (image.isPrimary)
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: QueensTouchColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('PRIMARY',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (!image.isPrimary)
          Positioned(
            left: 2,
            bottom: 2,
            child: InkWell(
              onTap: onSetPrimary,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: QueensTouchColors.plum,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Set primary',
                    style: TextStyle(color: QueensTouchColors.onGold, fontSize: 8, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }
}

class _PickedImage {
  const _PickedImage({required this.bytes, required this.filename, required this.mimeType});

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}