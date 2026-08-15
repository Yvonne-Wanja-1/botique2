import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/brand_header.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: QueensTouchColors.cream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandHeader(),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign in',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a demo account to preview the app.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: QueensTouchColors.textMuted,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        for (final account in DemoAccounts.accounts) ...[
                          _DemoAccountTile(
                            account: account,
                            onTap: () async {
                              await auth.loginAs(account);
                              if (account.role == Role.customer) {
                                context.go('/');
                              } else {
                                context.go('/admin');
                              }
                            },
                          ),
                          if (account != DemoAccounts.accounts.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Demo build — real authentication arrives with the backend.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QueensTouchColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  const _DemoAccountTile({required this.account, required this.onTap});

  final User account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStaff = account.role != Role.customer;
    return Material(
      color: isStaff ? QueensTouchColors.blushLight : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4D5DA)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: QueensTouchColors.plum,
                child: Text(
                  account.name.characters.first,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${account.role.label} · ${account.email}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: QueensTouchColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                isStaff ? Icons.dashboard_outlined : Icons.storefront_outlined,
                color: QueensTouchColors.plum,
              ),
            ],
          ),
        ),
      ),
    );
  }
}