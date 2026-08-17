import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../admin/admin_shell.dart';
import '../../customer/customer_shell.dart';
import '../../customer/catalog/product_detail_screen.dart';
import '../../customer/orders/order_detail_screen.dart';
import '../../customer/account/account_screen.dart';
import '../../features/login/login_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final auth = context.read<AuthService>();
        final loggedIn = auth.isLoggedIn;
        final path = state.matchedLocation;

        if (!loggedIn && path != '/login') {
          return '/login';
        }
        if (loggedIn && path == '/login') {
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
          path: '/login',
          builder: (context, state) => const LoginScreen(),
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