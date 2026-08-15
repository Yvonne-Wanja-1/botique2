import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'data/mock/mock_catalog_repositories.dart';
import 'data/mock/mock_commerce_repositories.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QueensTouchApp());
}

class QueensTouchApp extends StatelessWidget {
  const QueensTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..restoreSession()),
        ChangeNotifierProvider(
          create: (_) => CatalogService(
            MockProductRepository(),
            MockCategoryRepository(),
          )..loadHome(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartService(MockCartRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistService(MockWishlistRepository())..load(),
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
