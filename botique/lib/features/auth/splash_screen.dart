import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/brand_header.dart';
import '../../services/auth_service.dart';

/// Shown while the stored session is being restored from secure storage.
/// Once restoration completes it routes to the appropriate destination.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.status != AuthStatus.checking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (auth.isLoggedIn) {
          context.go(auth.isStaff ? '/admin' : '/');
        } else {
          context.go('/login');
        }
      });
    }
    return Scaffold(
      backgroundColor: QueensTouchColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            BrandHeader(),
            SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}