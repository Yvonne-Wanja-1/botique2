import 'package:flutter_test/flutter_test.dart';
import 'package:botique/models/product.dart';

void main() {
  test('Product.fromJson parses categorySlug', () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'Rosé Dress',
      'description': 'd',
      'basePrice': 10,
      'categoryId': '00000000-0000-0000-0000-000000000402',
      'categorySlug': 'clothing-dresses',
      'brandId': 'b1',
      'images': <String>[],
    });
    expect(product.categorySlug, 'clothing-dresses');
  });

  test('Product.fromJson defaults categorySlug to empty', () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'x',
      'description': '',
      'basePrice': 1,
      'categoryId': 'beauty-lip',
      'brandId': 'b1',
      'images': <String>[],
    });
    expect(product.categorySlug, '');
  });
}
