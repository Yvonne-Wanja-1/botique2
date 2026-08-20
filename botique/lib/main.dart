import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'data/api/api_bootstrap.dart';
import 'data/api/api_client.dart';
import 'data/mock/mock_catalog_repositories.dart';
import 'data/mock/mock_commerce_repositories.dart';
import 'data/mock/mock_report_repository.dart';
import 'data/mock/mock_review_repository.dart';
import 'data/repositories/api/api_notification_repository.dart';
import 'data/repositories/api/api_report_repository.dart';
import 'data/repositories/api/api_review_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/commerce_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/review_repository.dart';
import 'services/admin_catalog_service.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(QueensTouchApp(useApi: kUseApi, apiClient: kUseApi ? createApiClient() : null));
}

class QueensTouchApp extends StatefulWidget {
  const QueensTouchApp({super.key, this.useApi = false, this.apiClient});

  final bool useApi;
  final ApiClient? apiClient;

  @override
  State<QueensTouchApp> createState() => _QueensTouchAppState();
}

class _QueensTouchAppState extends State<QueensTouchApp> {
  late final ProductRepository _productRepo;
  late final CategoryRepository _categoryRepo;
  late final BrandRepository _brandRepo;
  late final CartRepository _cartRepo;
  late final WishlistRepository _wishlistRepo;
  late final OrderRepository _orderRepo;
  late final NotificationRepository _notificationRepo;
  late final ReviewRepository _reviewRepo;
  late final ReportRepository _reportRepo;

  @override
  void initState() {
    super.initState();
    final api = widget.useApi && widget.apiClient != null
        ? buildApiRepositories(widget.apiClient!)
        : null;
    _productRepo = api?.product ?? MockProductRepository();
    _categoryRepo = api?.category ?? MockCategoryRepository();
    _brandRepo = api?.brand ?? MockBrandRepository();
    _cartRepo = api?.cart ?? MockCartRepository();
    _wishlistRepo = api?.wishlist ?? MockWishlistRepository();
    _orderRepo = api?.order ?? MockOrderRepository();
    _notificationRepo = widget.apiClient != null
        ? ApiNotificationRepository(widget.apiClient!)
        : MockNotificationRepository();
    _reviewRepo = widget.apiClient != null
        ? ApiReviewRepository(widget.apiClient!)
        : MockReviewRepository();
    _reportRepo = widget.apiClient != null
        ? ApiReportRepository(widget.apiClient!)
        : MockReportRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthService(apiClient: widget.apiClient);
            auth.restoreSession();
            return auth;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogService(_productRepo, _categoryRepo)..loadHome(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminCatalogService(_productRepo, _categoryRepo, _brandRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => CartService(_cartRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistService(_wishlistRepo)..load(),
        ),
        Provider<OrderRepository>(create: (_) => _orderRepo),
        Provider<ReviewRepository>(create: (_) => _reviewRepo),
        Provider<ReportRepository>(create: (_) => _reportRepo),
        ChangeNotifierProvider(
          create: (_) => NotificationService(repo: _notificationRepo)..load(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Queens\' Touch',
        debugShowCheckedModeBanner: false,
        theme: QueensTouchTheme.light(),
        routerConfig: AppRouter.create(),
      ),
    );
  }
}