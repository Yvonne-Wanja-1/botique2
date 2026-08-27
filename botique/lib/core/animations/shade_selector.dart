import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

const Map<String, Color> kShadeColors = {
  'red': Color(0xFFC0392B),
  'rose': Color(0xFFB76E79),
  'nude': Color(0xFFD9B8A0),
  'berry': Color(0xFF8B3A5B),
  'plum': Color(0xFF6D2E4F),
  'coral': Color(0xFFE86A58),
  'pink': Color(0xFFE8A7B8),
  'mauve': Color(0xFFA98B8E),
  'brown': Color(0xFF6B4A2F),
  'black': Color(0xFF26211F),
  'tan': Color(0xFFC49A6C),
  'gold': Color(0xFFC9A24B),
  'beige': Color(0xFFE3C9A6),
  'burgundy': Color(0xFF6E1E2E),
  'peach': Color(0xFFF2B8A2),
  'maroon': Color(0xFF701D2B),
  'neutral': Color(0xFFD8BFA8),
};

/// Best-effort color for a cosmetic shade name; falls back to brand plum.
Color shadeColor(String shade) {
  final key = shade.trim().toLowerCase();
  final direct = kShadeColors[key];
  if (direct != null) return direct;
  for (final entry in kShadeColors.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return QueensTouchColors.plumLight;
}

/// Animated shade/color selection for cosmetics with a color-aware chip and
/// an animated selection indicator.
class ShadeSelector extends StatelessWidget {
  const ShadeSelector({
    super.key,
    required this.shades,
    required this.selected,
    required this.onSelected,
    this.label = 'Select Shade',
  });

  final List<String> shades;
  final String? selected;
  final ValueChanged<String> onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shade in shades)
              _ShadeChip(
                shade: shade,
                selected: selected == shade,
                onTap: () => onSelected(shade),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShadeChip extends StatelessWidget {
  const _ShadeChip({required this.shade, required this.selected, required this.onTap});

  final String shade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = shadeColor(shade);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: QtMotion.fast,
        curve: QtMotion.signature,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? QueensTouchColors.blushLight
              : QueensTouchColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : QueensTouchColors.surfaceBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: QtMotion.fast,
              curve: QtMotion.signature,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: selected ? 0.4 : 0.15),
                    blurRadius: selected ? 6 : 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              shade,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
