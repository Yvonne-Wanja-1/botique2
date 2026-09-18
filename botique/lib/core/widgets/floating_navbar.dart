import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
}

class FloatingNavbar extends StatelessWidget {
  const FloatingNavbar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 64;
  static const double _circleSize = 56;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: _barHeight + _circleSize / 2 + bottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const double margin = 16;
          final double pillWidth = width - margin * 2;
          final double itemWidth = pillWidth / items.length;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Pill bar ──
              Positioned(
                left: margin,
                right: margin,
                bottom: bottom,
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: QueensTouchColors.surfaceLight,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: QueensTouchColors.surfaceBorder.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tap targets (inactive items rendered here) ──
              Positioned(
                left: margin,
                right: margin,
                bottom: bottom,
                height: _barHeight,
                child: Row(
                  children: List.generate(items.length, (i) {
                    final bool selected = i == selectedIndex;
                    final item = items[i];
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: selected
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: QueensTouchColors.textMuted,
                                        size: 22,
                                      ),
                                      if (item.badge != null && item.badge! > 0)
                                        Positioned(
                                          right: -8,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: QueensTouchColors.danger,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${item.badge}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: QueensTouchColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                ),
              ),

              // ── Animated floating circle ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: margin + itemWidth * selectedIndex + (itemWidth - _circleSize) / 2,
                bottom: bottom + _barHeight - _circleSize / 2 - 8,
                child: GestureDetector(
                  onTap: () => onTap(selectedIndex),
                  child: Column(
                    children: [
                      Container(
                        width: _circleSize,
                        height: _circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              QueensTouchColors.plum,
                              QueensTouchColors.plumDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: QueensTouchColors.plum.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          items[selectedIndex].activeIcon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[selectedIndex].label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
