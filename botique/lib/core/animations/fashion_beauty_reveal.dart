import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Editorial top-to-bottom wipe reveal for fashion moments.
class FashionReveal extends StatelessWidget {
  const FashionReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (QtMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: QtMotion.slow,
      curve: QtMotion.signature,
      builder: (context, v, c) => ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, v.clamp(0.0, 1.0), (v + 0.001).clamp(0.0, 1.0)],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: c,
        ),
      ),
      child: child,
    );
  }
}

/// Soft radial glow bloom + gentle scale for cosmetics moments.
class BeautyReveal extends StatelessWidget {
  const BeautyReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (QtMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: QtMotion.slow,
      curve: QtMotion.signature,
      builder: (context, v, c) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              QueensTouchColors.goldLight.withValues(alpha: 0.5 * (1 - v)),
              Colors.transparent,
            ],
          ),
        ),
        child: Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.96 + 0.04 * v,
            child: c,
          ),
        ),
      ),
      child: child,
    );
  }
}
