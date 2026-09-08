import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../admin/admin_shell.dart';
import '../../customer/customer_shell.dart';
import '../../customer/catalog/product_detail_screen.dart';
import '../../customer/catalog/write_review_screen.dart';
import '../../customer/orders/order_detail_screen.dart';
import '../../customer/account/account_screen.dart';
import '../../customer/account/change_password_screen.dart';
import '../../customer/wishlist/wishlist_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final auth = context.read<AuthService>();
        final path = state.matchedLocation;

        // Session is still being restored from secure storage.
        if (auth.status == AuthStatus.checking) {
          return path == '/splash' ? null : '/splash';
        }

        final loggedIn = auth.isLoggedIn;
        final isPublic = path == '/login' || path == '/register';

        if (!loggedIn && !isPublic) {
          return '/login';
        }
        if (loggedIn && isPublic) {
          return auth.isStaff ? '/admin' : '/';
        }
        if (path.startsWith('/admin') && !auth.isStaff) {
          return '/';
        }
        if (path.startsWith('/customer') && auth.isStaff) {
          return '/admin';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomerShell(),
          routes: [
            GoRoute(
              path: 'product/:id',
              builder: (context, state) => ProductDetailScreen(
                productId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'product/:id/review',
              builder: (context, state) => WriteReviewScreen(
                productId: state.pathParameters['id']!,
                productName: state.extra as String? ?? '',
              ),
            ),
            GoRoute(
              path: 'account/profile',
              builder: (context, state) => const ProfileEditScreen(),
            ),
            GoRoute(
              path: 'account/order/:id',
              builder: (context, state) => OrderDetailScreen(
                orderId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'account/orders',
              builder: (context, state) => const OrderHistoryScreen(),
            ),
            GoRoute(
              path: 'account/payments',
              builder: (context, state) => const PaymentHistoryScreen(),
            ),
            GoRoute(
              path: 'account/installments',
              builder: (context, state) => const InstallmentsScreen(),
            ),
            GoRoute(
              path: 'account/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: 'account/wishlist',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('My Wishlist')),
                body: const WishlistScreen(),
              ),
            ),
            GoRoute(
              path: 'account/change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminShell(),
        ),
      ],
    );
  }
}