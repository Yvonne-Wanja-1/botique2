import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ClipOval(
              child: Opacity(
                opacity: 0.9,
                child: const Image(
                  image: AssetImage('lib/assets/images/icon.jpeg'),
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'QUEENS\' TOUCH BEAUTY SHOP',
              style: QueensTouchTheme.brandSerif(
                fontSize: 24,
                weight: FontWeight.w700,
                color: QueensTouchColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'ELEGANCE FOR EVERY QUEEN',
              style: TextStyle(
                color: QueensTouchColors.textMuted,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Our Story',
            style: QueensTouchTheme.brandSerif(
              fontSize: 20,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Queens\' Touch was born from a simple belief: every woman deserves access to '
            'carefully curated fashion and beauty products that celebrate her individuality. '
            'What started as a small boutique has grown into a destination for women who '
            'appreciate quality, elegance, and timeless style.',
            style: TextStyle(height: 1.6, color: QueensTouchColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'Our Mission',
            style: QueensTouchTheme.brandSerif(
              fontSize: 20,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'To empower every queen with fashion and beauty essentials that inspire '
            'confidence, celebrate individuality, and bring luxury within reach. We '
            'believe elegance is not about the price tag — it is about how you feel.',
            style: TextStyle(height: 1.6, color: QueensTouchColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'Why Choose Us',
            style: QueensTouchTheme.brandSerif(
              fontSize: 20,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _Feature(
            icon: Icons.workspace_premium,
            title: 'Curated Quality',
            description: 'Every piece is hand-selected for quality, style, and versatility.',
          ),
          _Feature(
            icon: Icons.local_shipping_outlined,
            title: 'Flat Rate Delivery',
            description: 'Affordable flat-rate delivery of KSh 200 across Kenya.',
          ),
          _Feature(
            icon: Icons.payment,
            title: 'Flexible Payment',
            description: 'Pay via M-Pesa Paybill or request installment plans.',
          ),
          _Feature(
            icon: Icons.favorite_outline,
            title: 'Customer First',
            description: 'Your satisfaction is our priority — easy returns and dedicated support.',
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Get in Touch',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const _ContactRow(icon: Icons.email_outlined, text: 'queenstouchbeauty333@gmail.com'),
          const SizedBox(height: 8),
          const _ContactRow(icon: Icons.phone_outlined, text: '0714 184 601'),
          const SizedBox(height: 8),
          const _ContactRow(icon: Icons.phone_outlined, text: '0725 865 727'),
          const SizedBox(height: 24),
          const Text(
            'Pay with M-Pesa',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const _ContactRow(icon: Icons.payment, text: 'Paybill: 222111'),
          const SizedBox(height: 8),
          const _ContactRow(icon: Icons.account_balance, text: 'Account: 65727'),
          const SizedBox(height: 24),
          const Text(
            'Follow Us',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.tiktok,
            text: 'TikTok',
            onTap: () => _launchUrl(context, 'https://www.tiktok.com/@yvonne0963?_r=1&_t=ZS-99ETqt9LR0K'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: QueensTouchColors.gold, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: QueensTouchColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: QueensTouchColors.gold, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: QueensTouchColors.textMuted)),
      ],
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: row);
    }
    return row;
  }
}

Future<void> _launchUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
