import 'package:flutter/material.dart';
import '../theme/theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.compact = false,
    this.color = QueensTouchColors.textDark,
  });

  final bool compact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'QUEENS\' TOUCH',
          style: TextStyle(
            fontSize: compact ? 18 : 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: color,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            'ELEGANCE FOR EVERY QUEEN',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 3,
              color: QueensTouchColors.gold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}