import 'package:flutter_test/flutter_test.dart';
import 'package:botique/core/animations/product_presentation.dart';

void main() {
  ProductPresentation p({String slug = '', String id = '', String name = ''}) =>
      presentationFor(categorySlug: slug, categoryId: id, categoryName: name);

  test('classifies fashion by slug', () {
    expect(p(slug: 'clothing-dresses'), ProductPresentation.fashion);
    expect(p(slug: 'clothing-jackets'), ProductPresentation.fashion);
  });

  test('classifies cosmetics by slug', () {
    expect(p(slug: 'beauty-lip'), ProductPresentation.lip);
    expect(p(slug: 'beauty-foundation'), ProductPresentation.foundation);
    expect(p(slug: 'beauty-blush'), ProductPresentation.powder);
    expect(p(slug: 'beauty-eyeshadow'), ProductPresentation.eyeshadow);
    expect(p(slug: 'beauty-skincare'), ProductPresentation.skincare);
    expect(p(slug: 'beauty-hair'), ProductPresentation.hair);
  });

  test('classifies perfume/fragrance slugs', () {
    expect(p(slug: 'perfume'), ProductPresentation.perfume);
    expect(p(slug: 'beauty-fragrance'), ProductPresentation.perfume);
  });

  test('falls back to categoryId when categorySlug is empty (mock data)', () {
    expect(p(id: 'clothing-dresses'), ProductPresentation.fashion);
    expect(p(id: 'beauty-lip'), ProductPresentation.lip);
  });

  test('falls back to product name keywords', () {
    expect(p(name: 'Velvet Matte Lipstick'), ProductPresentation.lip);
    expect(p(name: 'Luminous Foundation'), ProductPresentation.foundation);
    expect(p(name: 'Silk Garden Maxi Dress'), ProductPresentation.fashion);
  });

  test('returns generic when nothing matches', () {
    expect(p(), ProductPresentation.generic);
    expect(
      p(slug: 'misc-mystery', name: 'Gadget 3000'),
      ProductPresentation.generic,
    );
  });
}
