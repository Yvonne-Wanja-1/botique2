import 'package:flutter/material.dart';

import '../customer/home/home_screen.dart';
import '../customer/catalog/categories_screen.dart';
import '../customer/catalog/catalog_screen.dart';
import '../customer/cart/cart_screen.dart';
import '../customer/wishlist/wishlist_screen.dart';
import '../customer/account/account_screen.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  static const _titles = ['Queens\' Touch', 'Categories', 'My Cart', 'Wishlist', 'My Account'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
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
                icon: Badge(
                  isLabelVisible: ns.unreadCount > 0,
                  label: Text('${ns.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
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
          HomeScreen(),
          CategoriesScreen(),
          CartScreen(),
          WishlistScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Consumer<CartService>(
              builder: (context, cart, _) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            selectedIcon: Consumer<CartService>(
              builder: (context, cart, _) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Consumer<WishlistService>(
              builder: (context, wishlist, _) => Badge(
                isLabelVisible: wishlist.itemCount > 0,
                label: Text('${wishlist.itemCount}'),
                child: const Icon(Icons.favorite_outline),
              ),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}