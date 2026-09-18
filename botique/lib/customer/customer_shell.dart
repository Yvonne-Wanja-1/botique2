import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../core/widgets/floating_navbar.dart';
import '../customer/home/home_screen.dart';
import '../customer/catalog/categories_screen.dart';
import '../customer/catalog/catalog_screen.dart';
import '../customer/cart/cart_screen.dart';
import '../customer/wishlist/wishlist_screen.dart';
import '../customer/account/account_screen.dart';
import '../customer/about/about_us_screen.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../core/animations/qts_animation.dart';
import 'package:provider/provider.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 2;

  static const _titles = ['Categories', 'My Cart', 'Queens\' Touch', 'Wishlist', 'My Account'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _titles[_index],
          style: QueensTouchTheme.brandSerif(
            fontSize: 20,
            weight: FontWeight.w700,
            color: QueensTouchColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogScreen()),
            ),
          ),
          Consumer<NotificationService>(
            builder: (context, ns, _) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration:
                      QtMotion.reduceMotion(context) ? Duration.zero : QtMotion.fast,
                  child: Badge(
                    key: ValueKey(ns.unreadCount),
                    isLabelVisible: ns.unreadCount > 0,
                    label: Text('${ns.unreadCount}'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          CategoriesScreen(),
          CartScreen(),
          HomeScreen(),
          WishlistScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: Consumer2<CartService, WishlistService>(
        builder: (context, cart, wishlist, _) => FloatingNavbar(
          selectedIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            const FloatingNavItem(
              icon: Icons.category_outlined,
              activeIcon: Icons.category,
              label: 'Categories',
            ),
            FloatingNavItem(
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart,
              label: 'Cart',
              badge: cart.itemCount > 0 ? cart.itemCount : null,
            ),
            const FloatingNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            FloatingNavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: 'Wishlist',
              badge: wishlist.itemCount > 0 ? wishlist.itemCount : null,
            ),
            const FloatingNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [QueensTouchColors.plumDark, QueensTouchColors.plum],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Opacity(
                      opacity: 0.9,
                      child: const Image(
                        image: AssetImage('lib/assets/images/icon.jpeg'),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user != null)
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('My Cart'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Wishlist'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Account'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 4);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                '© 2026 Queens\' Touch',
                style: TextStyle(
                  color: QueensTouchColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}