import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'data/api/api_bootstrap.dart';
import 'data/api/api_client.dart';
import 'data/mock/mock_catalog_repositories.dart';
import 'data/mock/mock_commerce_repositories.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(QueensTouchApp(useApi: kUseApi, apiClient: kUseApi ? createApiClient() : null));
}

class QueensTouchApp extends StatelessWidget {
  const QueensTouchApp({super.key, this.useApi = false, this.apiClient});

  final bool useApi;
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    final ApiRepositories? api = useApi && apiClient != null ? buildApiRepositories(apiClient!) : null;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthService()..restoreSession();
            if (apiClient != null) {
              auth.addListener(() => syncPrincipal(apiClient!, auth.currentUser));
            }
            return auth;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogService(
            api?.product ?? MockProductRepository(),
            api?.category ?? MockCategoryRepository(),
          )..loadHome(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartService(api?.cart ?? MockCartRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistService(api?.wishlist ?? MockWishlistRepository())..load(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationService()),
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