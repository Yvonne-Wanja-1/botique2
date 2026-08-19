import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Star selection with smooth appearance and subtle scale on the tapped star.
class AnimatedStarRating extends StatelessWidget {
  const AnimatedStarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 40,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: enabled ? () => onChanged(i) : null,
            child: AnimatedScale(
              scale: i <= rating ? 1.0 : 0.9,
              duration: QtMotion.fast,
              curve: QtMotion.signature,
              child: AnimatedOpacity(
                opacity: i <= rating ? 1.0 : 0.45,
                duration: QtMotion.fast,
                child: Icon(
                  Icons.star,
                  size: size,
                  color: QueensTouchColors.gold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
