
import '../repositories/catalog_repository.dart';
import '../repositories/commerce_repository.dart';
import '../repositories/api/api_product_repository.dart';
import '../repositories/api/api_category_repository.dart';
import '../repositories/api/api_brand_repository.dart';
import '../repositories/api/api_cart_repository.dart';
import '../repositories/api/api_wishlist_repository.dart';
import '../repositories/api/api_order_repository.dart';
import '../repositories/api/api_promotion_repository.dart';
import 'api_client.dart';

/// Whether to use the live backend API instead of the mock repositories.
/// Defaults to the real backend; pass `--dart-define=USE_MOCK=true` to
/// opt back into the demo/mock build (used by tests).
const bool kUseApi = !bool.fromEnvironment('USE_MOCK');

/// Base URL for the Queens' Touch API backend.
/// On Android emulator use http://10.0.2.2:3000, on LAN use your machine IP.
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.100.12:3000');

ApiClient createApiClient() => ApiClient(baseUrl: kApiBaseUrl);

class ApiRepositories {
  const ApiRepositories({
    required this.product,
    required this.category,
    required this.brand,
    required this.cart,
    required this.wishlist,
    required this.order,
    required this.promotion,
  });

  final ProductRepository product;
  final CategoryRepository category;
  final BrandRepository brand;
  final CartRepository cart;
  final WishlistRepository wishlist;
  final OrderRepository order;
  final PromotionRepository promotion;
}

ApiRepositories buildApiRepositories(ApiClient client) => ApiRepositories(
      product: ApiProductRepository(client),
      category: ApiCategoryRepository(client),
      brand: ApiBrandRepository(client),
      cart: ApiCartRepository(client),
      wishlist: ApiWishlistRepository(client),
      order: ApiOrderRepository(client),
      promotion: ApiPromotionRepository(client),
    );