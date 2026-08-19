import 'package:flutter/widgets.dart';

/// Central motion tokens for the Queens' Touch brand.
abstract final class QtMotion {
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 650);

  /// Signature easing — a gentle ease-out that feels like fabric settling.
  static const Curve signature = Curves.easeOutCubic;
  static const Curve signatureInOut = Curves.easeInOutCubic;

  /// True when the platform requests reduced motion or animations are disabled.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
