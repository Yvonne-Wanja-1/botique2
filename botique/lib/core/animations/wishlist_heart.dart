import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Wishlist heart with a subtle scale bounce and soft glow on selection.
class WishlistHeart extends StatefulWidget {
  const WishlistHeart({
    super.key,
    required this.isSelected,
    required this.onPressed,
    this.size = 24,
    this.color = QueensTouchColors.danger,
  });

  final bool isSelected;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  @override
  State<WishlistHeart> createState() => _WishlistHeartState();
}

class _WishlistHeartState extends State<WishlistHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: QtMotion.normal,
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant WishlistHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: QtMotion.signature);
    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final bounce = 1.0 + 0.25 * (1 - (1 - _controller.value) * (1 - _controller.value));
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isSelected)
                Container(
                  width: widget.size * 1.7,
                  height: widget.size * 1.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.14 * scale.value),
                  ),
                ),
              Transform.scale(
                scale: bounce,
                child: Icon(
                  widget.isSelected ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color: widget.isSelected ? widget.color : QueensTouchColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
