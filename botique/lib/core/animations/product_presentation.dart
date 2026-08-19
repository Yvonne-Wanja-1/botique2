/// The visual treatment applied to a product based on its category.
/// Category-aware, never product- or filename-specific.
enum ProductPresentation {
  fashion,
  lip,
  foundation,
  powder,
  eyeshadow,
  skincare,
  perfume,
  hair,
  accessory,
  generic,
}

/// Resolves the presentation for a product from its category slug/id/name.
///
/// Precedence: category slug (or category id, which mock data uses as a slug),
/// then product-name keywords, then [ProductPresentation.generic].
ProductPresentation presentationFor({
  String categorySlug = '',
  String categoryId = '',
  String categoryName = '',
}) {
  final slug = (categorySlug.isNotEmpty ? categorySlug : categoryId)
      .toLowerCase()
      .trim();
  final name = categoryName.toLowerCase().trim();

  ProductPresentation? bySlug(String s) {
    if (s.isEmpty) return null;
    if (s.contains('clothing') || s.contains('apparel')) {
      return ProductPresentation.fashion;
    }
    if (s.contains('lip')) return ProductPresentation.lip;
    if (s.contains('foundation') || s.contains('concealer')) {
      return ProductPresentation.foundation;
    }
    if (s.contains('blush') || s.contains('powder')) {
      return ProductPresentation.powder;
    }
    if (s.contains('eyeshadow')) return ProductPresentation.eyeshadow;
    if (s.contains('skincare') || s.contains('skin-care')) {
      return ProductPresentation.skincare;
    }
    if (s.contains('perfume') ||
        s.contains('fragrance') ||
        s.contains('cologne')) {
      return ProductPresentation.perfume;
    }
    if (s.contains('hair')) return ProductPresentation.hair;
    if (s.contains('accessor')) return ProductPresentation.accessory;
    return null;
  }

  ProductPresentation? byName(String n) {
    if (n.isEmpty) return null;
    final tokens = n
        .split(RegExp(r'[^a-z]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final exact = <String, ProductPresentation>{
      'lip': ProductPresentation.lip,
      'lipstick': ProductPresentation.lip,
      'lipgloss': ProductPresentation.lip,
      'foundation': ProductPresentation.foundation,
      'concealer': ProductPresentation.foundation,
      'blush': ProductPresentation.powder,
      'powder': ProductPresentation.powder,
      'eyeshadow': ProductPresentation.eyeshadow,
      'palette': ProductPresentation.eyeshadow,
      'serum': ProductPresentation.skincare,
      'skincare': ProductPresentation.skincare,
      'moisturizer': ProductPresentation.skincare,
      'cleanser': ProductPresentation.skincare,
      'toner': ProductPresentation.skincare,
      'perfume': ProductPresentation.perfume,
      'fragrance': ProductPresentation.perfume,
      'cologne': ProductPresentation.perfume,
      'dress': ProductPresentation.fashion,
      'gown': ProductPresentation.fashion,
      'skirt': ProductPresentation.fashion,
      'trousers': ProductPresentation.fashion,
      'jeans': ProductPresentation.fashion,
      'jacket': ProductPresentation.fashion,
      'blouse': ProductPresentation.fashion,
      'jumpsuit': ProductPresentation.fashion,
      'shirt': ProductPresentation.fashion,
      'coat': ProductPresentation.fashion,
      'sweater': ProductPresentation.fashion,
      'cardigan': ProductPresentation.fashion,
      'shampoo': ProductPresentation.hair,
      'conditioner': ProductPresentation.hair,
    };
    for (final token in tokens) {
      final hit = exact[token];
      if (hit != null) return hit;
    }
    return null;
  }

  return bySlug(slug) ?? byName(name) ?? ProductPresentation.generic;
}
