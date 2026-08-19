
import '../../models/user.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/commerce_repository.dart';
import '../repositories/api/api_product_repository.dart';
import '../repositories/api/api_category_repository.dart';
import '../repositories/api/api_brand_repository.dart';
import '../repositories/api/api_cart_repository.dart';
import '../repositories/api/api_wishlist_repository.dart';
import '../repositories/api/api_order_repository.dart';
import 'api_client.dart';

/// Whether to use the live backend API instead of the mock repositories.
const bool kUseApi = bool.fromEnvironment('USE_API');

/// Base URL for the Queens' Touch API backend.
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

ApiClient createApiClient() => ApiClient(baseUrl: kApiBaseUrl);

class ApiRepositories {
  const ApiRepositories({
    required this.product,
    required this.category,
    required this.brand,
    required this.cart,
    required this.wishlist,
    required this.order,
  });

  final ProductRepository product;
  final CategoryRepository category;
  final BrandRepository brand;
  final CartRepository cart;
  final WishlistRepository wishlist;
  final OrderRepository order;
}

ApiRepositories buildApiRepositories(ApiClient client) => ApiRepositories(
      product: ApiProductRepository(client),
      category: ApiCategoryRepository(client),
      brand: ApiBrandRepository(client),
      cart: ApiCartRepository(client),
      wishlist: ApiWishlistRepository(client),
      order: ApiOrderRepository(client),
    );

/// Maps demo-account roles to the seeded backend user UUIDs so the auth-stub
/// enforcement and data lookups resolve against the seeded database.
String? _seededUserId(Role role) => switch (role) {
      Role.customer => '00000000-0000-0000-0000-000000000201',
      Role.superAdmin => '00000000-0000-0000-0000-000000000202',
      Role.storeManager => '00000000-0000-0000-0000-000000000203',
      Role.salesStaff => '00000000-0000-0000-0000-000000000204',
      Role.inventoryStaff => '00000000-0000-0000-0000-000000000205',
    };

String? _roleToApi(Role role) => switch (role) {
      Role.superAdmin => 'super_admin',
      Role.storeManager => 'store_manager',
      Role.salesStaff => 'sales_staff',
      Role.inventoryStaff => 'inventory_staff',
      Role.customer => 'customer',
    };

/// Syncs the ApiClient principal from an AuthService user. Uses the seeded
/// backend user id for the demo role so backend queries resolve.
void syncPrincipal(ApiClient client, User? user) {
  if (user == null) {
    client.clearPrincipal();
    return;
  }
  client.setPrincipal(userId: _seededUserId(user.role), role: _roleToApi(user.role));
}