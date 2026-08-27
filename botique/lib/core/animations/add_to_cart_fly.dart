import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/image_url.dart';
import 'qts_animation.dart';

/// Elevated "Add to Cart" button that briefly morphs to a confirmation after
/// [onPressed] fires. Non-blocking and fast.
class AddToCartButton extends StatefulWidget {
  const AddToCartButton({
    super.key,
    required this.onPressed,
    this.label = 'Add to Cart',
    this.icon = Icons.add_shopping_cart,
    this.confirmLabel = 'Added to Bag',
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String confirmLabel;
  final bool enabled;

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton>
    with SingleTickerProviderStateMixin {
  bool _confirmed = false;
  late final AnimationController _reset;

  @override
  void initState() {
    super.initState();
    _reset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _confirmed = false);
        }
      });
  }

  @override
  void dispose() {
    _reset.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onPressed();
    if (mounted) setState(() => _confirmed = true);
    _reset.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.enabled ? _handleTap : null,
      icon: AnimatedSwitcher(
        duration: QtMotion.fast,
        child: _confirmed
            ? const Icon(Icons.check, key: ValueKey('check'))
            : Icon(widget.icon, key: const ValueKey('icon')),
      ),
      label: AnimatedSwitcher(
        duration: QtMotion.fast,
        child: Text(
          _confirmed ? widget.confirmLabel : widget.label,
          key: ValueKey(_confirmed),
        ),
      ),
    );
  }
}

/// Flies a product thumbnail toward the top-right of the screen to give
/// add-to-cart a satisfying physical gesture. Pure presentation; does not
/// depend on widget geometry of the cart badge.
class AddToCartFly {
  AddToCartFly._();

  static void show(
    BuildContext context, {
    required String imageUrl,
    Rect? from,
    double size = 56,
  }) {
    final overlay = Overlay.of(context);
    final screen = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final start = from ??
        Rect.fromCenter(
          center: screen.center(Offset.zero),
          width: size,
          height: size,
        );
    final end = Rect.fromLTWH(screen.width - size - 20, topPad + 24, size, size);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyOverlay(
        imageUrl: imageUrl,
        from: start,
        to: end,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyOverlay extends StatefulWidget {
  const _FlyOverlay({
    required this.imageUrl,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String imageUrl;
  final Rect from;
  final Rect to;
  final VoidCallback onDone;

  @override
  State<_FlyOverlay> createState() => _FlyOverlayState();
}

class _FlyOverlayState extends State<_FlyOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: _controller, curve: QtMotion.signatureInOut);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            final left = widget.from.left + (widget.to.left - widget.from.left) * t;
            final top = widget.from.top + (widget.to.top - widget.from.top) * t;
            final size = widget.from.width + (widget.to.width - widget.from.width) * t;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: t < 0.8 ? 1.0 : (1 - t) * 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.imageUrl.trim().isEmpty
                          ? Container(
                              color: QueensTouchColors.plum,
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: QueensTouchColors.onGold,
                              ),
                            )
                          : Image.network(
                              resolveImageUrl(widget.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: QueensTouchColors.plum,
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: QueensTouchColors.onGold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
