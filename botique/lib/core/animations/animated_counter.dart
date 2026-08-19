import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// Smoothly animates between numeric values, formatting each intermediate
/// value with [format]. Skips animation under reduced motion.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.format,
    this.duration = QtMotion.normal,
    this.style,
    this.textAlign,
  });

  final double value;
  final String Function(double value) format;
  final Duration duration;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: QtMotion.reduceMotion(context) ? Duration.zero : duration,
      curve: QtMotion.signature,
      builder: (context, v, _) =>
          Text(format(v), style: style, textAlign: textAlign),
    );
  }
}
