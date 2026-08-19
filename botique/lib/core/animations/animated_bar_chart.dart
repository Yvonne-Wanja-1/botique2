import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Bars animate to their height once on first display and on value changes
/// (keyed per label so data changes replay the entrance).
class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = QueensTouchColors.plum,
    this.height = 120,
    this.barRadius = 4,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final double barRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('${labels[i]}-${values[i]}'),
                          tween: Tween(
                            begin: QtMotion.reduceMotion(context) ? 1.0 : 0.0,
                            end: 1.0,
                          ),
                          duration: QtMotion.slow,
                          curve: QtMotion.signature,
                          builder: (context, v, _) => FractionallySizedBox(
                            heightFactor: v,
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == values.length - 1
                                    ? color
                                    : color.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(barRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: QueensTouchColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}